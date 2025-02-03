include { BIOINFOTONGLI_CELLPOSE as CELLPOSE } from '../../../modules/sanger/bioinfotongli/cellpose/main'
include { BIOINFOTONGLI_STARDIST as STARDIST} from '../../../modules/sanger/bioinfotongli/stardist/main'
include { MERGEOUTLINES} from '../../../modules/sanger/mergeoutlines/main'
include { BIOINFOTONGLI_GENERATETILES as GENERATE_TILE_COORDS } from '../../../modules/sanger/bioinfotongli/generatetiles/main'


workflow TILED_SEGMENTATION {
    take:
    images 
    method

    main:
    ch_versions = Channel.empty()
    GENERATE_TILE_COORDS(images)
    ch_versions = ch_versions.mix(GENERATE_TILE_COORDS.out.versions.first())

    images_tiles = GENERATE_TILE_COORDS.out.tile_coords.splitCsv(header:true, sep:",").map{ meta, coords ->
        [meta, coords.X_MIN, coords.Y_MIN, coords.X_MAX, coords.Y_MAX]
    }

    if (method == "CELLPOSE") {
        CELLPOSE(images_tiles.combine(images, by:0).combine(channel.from(params.cell_diameters)))
        wkts = CELLPOSE.out.wkts.groupTuple(by:[0,1])
        ch_versions = ch_versions.mix(CELLPOSE.out.versions.first())
    } else if (method == "STARDIST") {
        STARDIST(images_tiles.combine(images, by:0))
        wkts = STARDIST.out.wkts.groupTuple(by:[0,1])
        ch_versions = ch_versions.mix(STARDIST.out.versions.first())
    } else {
        error "Invalid segmentation method: ${method}"
    }
    MERGEOUTLINES(wkts)
    ch_versions = ch_versions.mix(MERGEOUTLINES.out.versions.first())

    emit:
    wkt         = MERGEOUTLINES.out.multipoly_wkts   // channel: [ val(meta), [ wkt ] ]
    versions    = ch_versions                     // channel: [ versions.yml ]
}