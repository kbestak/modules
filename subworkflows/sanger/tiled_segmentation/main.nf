include { BIOINFOTONGLI_CELLPOSE as CELLPOSE } from '../../../modules/sanger/bioinfotongli/cellpose/main'
include { BIOINFOTONGLI_STARDIST as STARDIST} from '../../../modules/sanger/bioinfotongli/stardist/main'
include { BIOINFOTONGLI_INSTANSEG as INSTANSEG} from '../../../modules/sanger/bioinfotongli/instanseg/main'
include { BIOINFOTONGLI_DEEPCELL as DEEPCELL} from '../../../modules/sanger/bioinfotongli/deepcell/main'
include { MERGEOUTLINES} from '../../../modules/sanger/mergeoutlines/main'
include { BIOINFOTONGLI_GENERATETILES as GENERATE_TILE_COORDS } from '../../../modules/sanger/bioinfotongli/generatetiles/main'


workflow TILED_SEGMENTATION {
    take:
    images
    method

    main:
    ch_versions = Channel.empty()
    ch_images   = Channel.of(images)

    // Generate tile coords

    GENERATE_TILE_COORDS(ch_images)
    ch_versions = ch_versions.mix(GENERATE_TILE_COORDS.out.versions)
    images_tiles = GENERATE_TILE_COORDS.out.tile_coords.splitCsv(header:true, sep:",").map{ meta, coords ->
        [meta, coords.X_MIN, coords.Y_MIN, coords.X_MAX, coords.Y_MAX]
    }
    tiles_and_images = images_tiles.combine(ch_images, by:0)

    if (method == "CELLPOSE") {
        CELLPOSE(tiles_and_images.map { it + [params.cell_diameter] })
        wkts = CELLPOSE.out.wkts
        ch_versions = ch_versions.mix(CELLPOSE.out.versions)
    } else if (method == "STARDIST") {
        STARDIST(tiles_and_images)
        wkts = STARDIST.out.wkts
        ch_versions = ch_versions.mix(STARDIST.out.versions)
    } else if (method == "INSTANSEG") {
        INSTANSEG(tiles_and_images)
        wkts = INSTANSEG.out.wkts
        ch_versions = ch_versions.mix(INSTANSEG.out.versions)
    } else if (method == "DEEPCELL") {
        DEEPCELL(tiles_and_images)
        wkts = DEEPCELL.out.wkts
        ch_versions = ch_versions.mix(DEEPCELL.out.versions)
    } else {
        error "Invalid segmentation method: ${method}"
    }
    wkts.view()
    MERGEOUTLINES(wkts)
    MERGEOUTLINES.out.multipoly_geojsons.view()
    ch_versions = ch_versions.mix(MERGEOUTLINES.out.versions)

    ch_multipoly_geojsons = MERGEOUTLINES.out.multipoly_geojsons


    emit:
    wkt         = ch_multipoly_geojsons  // channel: [ val(meta), [ geojson ] ]
    versions    = ch_versions                            // channel: [ versions.yml ]
}