import React, { useMemo,useState } from 'react';
import { usePlane } from '@react-three/cannon';
import {
  TextureLoader,
  RepeatWrapping,
  NearestFilter,
  LinearMipMapLinearFilter,
} from 'three';
import { useCursor } from '@react-three/drei'

import { useStore } from '/src/hooks/useStore';

export const Ground = (props) => {
  const [hovered, set] = useState()
  useCursor(hovered, /*'pointer', 'auto'*/)

  const [addCube, activeTexture,position,ground] = useStore((state) => [
    state.addCube,
    state.texture,
    state.position,
    state.ground,
  ]);
  

  const [ref] = usePlane(() => ({ rotation: [-Math.PI / 2, 0, 0], position:[ground[0],ground[1],ground[2]]}));

  const texture = useMemo(() => {
    const t = new TextureLoader().load("/images/grass.png")
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
          e.stopPropagation();
          const [x, y, z] = Object.values(e.point).map((coord) =>
            Math.ceil(coord)
          );
          console.log("addCube",x,y,z)
          addCube(x, y, z, activeTexture);
        }}
        
        onPointerOver={() => set(true)} onPointerOut={() => set(false)}
      >
        <planeBufferGeometry attach="geometry" args={[ground[3],ground[4]]} />

        <meshStandardMaterial  attach="material" 
        color="#a6a6a6"
        />
      </mesh>
  );
};
