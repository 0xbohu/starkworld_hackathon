import React, { memo, useMemo,useState,useRef, } from 'react';
import { useBox } from '@react-three/cannon';
import { TextureLoader,NearestFilter, LinearMipMapLinearFilter} from 'three';
import {  useThree, useFrame } from "@react-three/fiber";

const CubeHelper = ({ position}) => {
  const [hover, setHover] = useState(null);

  const ref = useRef()
  const { viewport } = useThree()
  useFrame(({ mouse }) => {
    const x = (mouse.x * viewport.width) / 2
    const y = ((mouse.y * viewport.height) / 2) + 5
    ref.current.position.set(x, y, 0)
    ref.current.rotation.set(-y, x, 0)
  })


  const color = 'skyblue';

  const textureLoader = useMemo(() => {
    const t = new TextureLoader().load("/images/wood.png")
    t.magFilter = NearestFilter
    t.minFilter = LinearMipMapLinearFilter
    return t
  }, [])


  return (
    <mesh
      castShadow
      ref={ref}
      onPointerMove={(e) => {
        // e.stopPropagation();
        setHover(Math.floor(e.faceIndex / 2));
      }}
      onPointerOut={() => {
        setHover(null);
      }}

    //   onClick={(e) => {
    //     e.stopPropagation();
    //     const clickedFace = Math.floor(e.faceIndex / 2);
    //     const { x, y, z } = ref.current.position;
    //     if (clickedFace === 0) {
    //       e.altKey ? removeCube(x, y, z) : addCube(x + 1, y, z);
    //       return;
    //     }
    //     if (clickedFace === 1) {
    //       e.altKey ? removeCube(x, y, z) : addCube(x - 1, y, z);
    //       return;
    //     }
    //     if (clickedFace === 2) {
    //       e.altKey ? removeCube(x, y, z) : addCube(x, y + 1, z);
    //       return;
    //     }
    //     if (clickedFace === 3) {
    //       e.altKey ? removeCube(x, y, z) : addCube(x, y - 1, z);
    //       return;
    //     }
    //     if (clickedFace === 4) {
    //       e.altKey ? removeCube(x, y, z) : addCube(x, y, z + 1);
    //       return;
    //     }
    //     if (clickedFace === 5) {
    //       e.altKey ? removeCube(x, y, z) : addCube(x, y, z - 1);
    //       return;
    //     }
    //   }}
    >
      <boxBufferGeometry attach="geometry" />{' '}
      <meshStandardMaterial
        attach="material"
        // map={textures[texture]}
        map = {textureLoader}
        color={hover != null ? 'red' : color}
        opacity={0.7}
        transparent={true}
      />
     
    </mesh>
  );
};

function equalProps(prevProps, nextProps) {
  const equalPosition = prevProps.position?(
    prevProps.position.x === nextProps.position.x &&
    prevProps.position.y === nextProps.position.y &&
    prevProps.position.z === nextProps.position.z):false;

  return equalPosition && prevProps.texture === nextProps.texture;
}

export default memo(CubeHelper, equalProps);
