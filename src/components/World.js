import React, { useMemo } from 'react';
import { usePlane } from '@react-three/cannon';
import {
  TextureLoader,
  RepeatWrapping,
  NearestFilter,
  LinearMipMapLinearFilter,
  BackSide,
} from 'three';
import { Html, Billboard } from '@react-three/drei'

import { useStore } from '../hooks/useStore';

export const World = (props) => {
  const [ref] = usePlane(() => ({ rotation: [-Math.PI / 2, 0, 0], ...props }));

  const texture = useMemo(() => {
    const t = new TextureLoader().load('/images/g4.png')
    t.wrapS = RepeatWrapping
    t.wrapT = RepeatWrapping
    t.repeat.set(10, 10)
    return t
  }, [])

  texture.magFilter = NearestFilter;
  texture.minFilter = LinearMipMapLinearFilter;
  texture.wrapS = RepeatWrapping;
  texture.wrapT = RepeatWrapping;
  texture.repeat.set(10, 10);

  return (
    <mesh
          ref={ref}
          receiveShadow
        >
          <planeBufferGeometry attach="geometry" args={[props.x,props.y]} />

          <meshStandardMaterial  attach="material" 
          color="#a6a6a6"
          // map={texture}
          // opacity={0.1}
          />
          <Billboard
            follow={true}
            lockX={true}
            lockY={true}
            lockZ={false}
          >
          <Html 
            scale={1.5} 
            rotation={[Math.PI / 2, 0, 0]} 
            position={[0, 0, 2]}
            transform 
            occlude
            >
              <div style={{ fontSize: '1.5em',color: '#026cde', style:"none" }}> Land # {props.tid}<span style={{ fontSize: '1.5em' }}></span>
              </div>
            </Html>
            </Billboard>
    </mesh>
  );
};
