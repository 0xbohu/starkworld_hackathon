import React, { useMemo,useState } from 'react';
import { usePlane } from '@react-three/cannon';
import {
  TextureLoader,
  RepeatWrapping,
  NearestFilter,
  LinearMipMapLinearFilter,
} from 'three';

export const Landscape = (props) => {

  const [ref] = usePlane(() => ({ rotation: [-Math.PI / 2, 0, 0], position:[0,-0.05,0]}));
  
  const texture = useMemo(() => {
    const t = new TextureLoader().load('/images/tile.png')
    t.wrapS = RepeatWrapping
    t.wrapT = RepeatWrapping
    t.repeat.set(500, 500)
    return t
  }, [])

  texture.magFilter = NearestFilter;
  texture.minFilter = LinearMipMapLinearFilter;
  texture.wrapS = RepeatWrapping;
  texture.wrapT = RepeatWrapping;
  texture.repeat.set(500, 500);

  const handleClick = (e) => {
    // e.stopPropagation();
  }

  return (
      <mesh
        ref={ref}
        receiveShadow
        onClick={(e) => {
        //   e.stopPropagation();
        }}
      >
        <planeBufferGeometry attach="geometry" args={[10000,10000]} />

        <meshStandardMaterial  attach="material" 
        map={texture} 
        />

      </mesh>
  );
};
