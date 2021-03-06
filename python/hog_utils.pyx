# cython: profile=True
# cython: boundscheck=False
# cython: wraparound=False

import numpy as np
cimport numpy as np
DTYPE = np.float32
ctypedef np.float32_t DTYPE_t

import cv,cv2

def ReshapeHog(np.ndarray[DTYPE_t, ndim=2] feature_vector, dims, blockSize, winSize, nbins):
    cdef int iblocks_per_window=winSize[0]/blockSize[0]
    cdef int jblocks_per_window=winSize[1]/blockSize[1]

    cdef int iwindows=dims[0]/winSize[0]
    cdef int jwindows=dims[1]/winSize[1]

    cdef np.ndarray[DTYPE_t, ndim=3] feature_vector_3d=np.zeros((iwindows*iblocks_per_window*2,
                                jwindows*jblocks_per_window*2,nbins), dtype=DTYPE)

    cdef int idx = 0
    cdef int ywin, xwin, x, y, win_x, win_y, cell_x, cell_y
    cdef int i, cell_off_x, cell_off_y
    
    for ywin in range(iwindows):
        for xwin in range(jwindows):
            win_x=xwin*jblocks_per_window*2
            win_y=ywin*iblocks_per_window*2
            for x in range(jblocks_per_window):
                for y in range(iblocks_per_window):
                    cell_x=x*2
                    cell_y=y*2
                    # 4 cells per block
                    for i in range(4):
                        cell_off_y=0; cell_off_x=0
                        if (i==1):
                            cell_off_y=1
                        elif (i==2):
                            cell_off_x=1
                        elif (i==3):
                            cell_off_x=1
                            cell_off_y=1

                        feature_vector_3d[win_y+cell_y+cell_off_y, win_x+cell_x+cell_off_x,:]=np.squeeze(feature_vector[idx:idx+nbins])
                        idx+=nbins

    return feature_vector_3d
    
def draw_hog2(I,hog,feature_vector):
    feature_vector_3d = ReshapeHog(I, hog, feature_vector)
    # glyph size
    w=15
    bar=np.zeros((w,w))
    bar[:,np.round(.45*w):np.round(.55*w)]=1;
    bar[w/2+1,w/2+1]=0;

    hog_viz=np.zeros((w*feature_vector_3d.shape[0],
                      w*feature_vector_3d.shape[1]))
    for i in range(feature_vector_3d.shape[0]):
        for j in range(feature_vector_3d.shape[1]):
            for o in range(feature_vector_3d.shape[2]):
                # copy and rotate bar
                degs=(float(o)/feature_vector_3d.shape[2])*180
                bar1=np.copy(bar)
                rot_mat=cv2.getRotationMatrix2D((np.round(w/2),np.round(w/2)),degs,1)
                bar1_rot=cv2.warpAffine(bar1, rot_mat, bar1.shape)
                val=feature_vector_3d[i,j,o]
                hog_viz[i*w:(i+1)*w,j*w:(j+1)*w]=hog_viz[i*w:(i+1)*w,j*w:(j+1)*w]+bar1_rot*val
                # rotate a patch based on 'o'
                # darken patch based on value
                # add result to location specified by (i,j)
    return hog_viz


def draw_hog(I,hog,feature_vector):
    # glyph size
    w=15
    bar=np.zeros((w,w))
    bar[:,np.round(.45*w):np.round(.55*w)]=1;
    bar[w/2+1,w/2+1]=0;

    iblocks_per_window=hog.winSize[0]/hog.blockSize[0]
    jblocks_per_window=hog.winSize[1]/hog.blockSize[1]

    iwindows=I.shape[0]/hog.winSize[0]
    jwindows=I.shape[1]/hog.winSize[1]

    feature_vector_3d=np.zeros((iwindows*iblocks_per_window*2,
                                jwindows*jblocks_per_window*2,hog.nbins))

    idx=0;
    for ywin in range(iwindows):
        for xwin in range(jwindows):
            win_x=xwin*jblocks_per_window*2
            win_y=ywin*iblocks_per_window*2
            for x in range(jblocks_per_window):
                for y in range(iblocks_per_window):
                    cell_x=x*2
                    cell_y=y*2
                    # 4 cells per block
                    for i in range(4):
                        cell_off_y=0; cell_off_x=0
                        if (i==1):
                            cell_off_y=1
                        elif (i==2):
                            cell_off_x=1
                        elif (i==3):
                            cell_off_x=1
                            cell_off_y=1
                        for o in range(hog.nbins):
                            feature_vector_3d[win_y+cell_y+cell_off_y,
                                              win_x+cell_x+cell_off_x,o]=feature_vector[idx]
                            idx+=1

    hog_viz=np.zeros((w*feature_vector_3d.shape[0],
                      w*feature_vector_3d.shape[1]))
    for i in range(feature_vector_3d.shape[0]):
        for j in range(feature_vector_3d.shape[1]):
            for o in range(feature_vector_3d.shape[2]):
                # copy and rotate bar
                degs=(float(o)/feature_vector_3d.shape[2])*180
                bar1=np.copy(bar)
                rot_mat=cv2.getRotationMatrix2D((np.round(w/2),np.round(w/2)),degs,1)
                bar1_rot=cv2.warpAffine(bar1, rot_mat, bar1.shape)
                val=feature_vector_3d[i,j,o]
                hog_viz[i*w:(i+1)*w,j*w:(j+1)*w]=hog_viz[i*w:(i+1)*w,j*w:(j+1)*w]+bar1_rot*val
                # rotate a patch based on 'o'
                # darken patch based on value
                # add result to location specified by (i,j)
    return hog_viz


