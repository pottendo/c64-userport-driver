#importonce

//.segmentdef _main [startAfter="Default"]
//.segmentdef _cmds [startAfter="_main"]
//.segmentdef _screen [startAfter="_cmds"]
//.segmentdef _par_drv [startAfter="_screen"]
//.segmentdef _pottendo_utils [startAfter="_par_drv"]
//.segmentdef _data [startAfter="_pottendo_utils"]

.namespace gl {
    .label vic_base = $8000
    .label vic_videoram = vic_base + $0000 //$3c00
    .label dest_mem = vic_base + $2000
    .label gfx_buf = $c000
}