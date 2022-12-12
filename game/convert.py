import struct

def bsp_to_obj(bsp_path, obj_path):
    with open(bsp_path, 'rb') as f:
        data = f.read()

    # GoldSrc BSP Header: Version 30
    version = struct.unpack('<I', data[0:4])[0]
    if version != 30:
        print("Error: Not a CS 1.6 BSP file.")
        return

    # Lumps
    lumps = []
    for i in range(15):
        offset, length = struct.unpack('<II', data[4 + i * 8 : 4 + (i + 1) * 8])
        lumps.append({'offset': offset, 'length': length})

    def read_lump(lump_index, struct_fmt):
        lump = lumps[lump_index]
        size = struct.calcsize(struct_fmt)
        count = lump['length'] // size
        items = []
        for i in range(count):
            start = lump['offset'] + i * size
            items.append(struct.unpack(struct_fmt, data[start : start + size]))
        return items

    raw_vertices = read_lump(3, '<3f') 
    raw_edges = read_lump(12, '<HH')
    
    surfedges = []
    lump13 = lumps[13]
    for i in range(lump13['length'] // 4):
        val = struct.unpack('<i', data[lump13['offset'] + i*4 : lump13['offset'] + (i+1)*4])[0]
        surfedges.append(val)

    raw_faces = read_lump(7, '<HH I H H 4B I')

    obj_lines = ["# Converted Map"]
    scale = 0.06 
    for v in raw_vertices:
        obj_lines.append(f"v {v[0]*scale:.4f} {v[2]*scale:.4f} {-v[1]*scale:.4f}")

    for face in raw_faces:
        first_surfedge_idx = face[2]
        num_surfedges = face[3]
        face_vertex_indices = []
        for i in range(num_surfedges):
            edge_index = surfedges[first_surfedge_idx + i]
            if edge_index >= 0:
                v_idx = raw_edges[edge_index][0]
            else:
                v_idx = raw_edges[-edge_index][1]
            face_vertex_indices.append(str(v_idx + 1))
        
        if len(face_vertex_indices) >= 3:
            obj_lines.append(f"f {' '.join(face_vertex_indices)}")

    with open(obj_path, 'w') as f:
        f.write('\n'.join(obj_lines))
    print(f"Created {obj_path}")

# Change this filename to match your exact file location if needed
bsp_to_obj("hns_floppytown.bsp", "hns_floppytown.obj")