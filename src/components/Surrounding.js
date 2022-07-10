import React, { memo, useMemo,useState } from 'react';
import { useBox } from '@react-three/cannon';
import { TextureLoader,NearestFilter, LinearMipMapLinearFilter} from 'three';
const Surrounding = ({ position, texture, }) => {
  const [hover, setHover] = useState(null);

  const [ref] = useBox(() => ({
    type: 'Static',
    position,
  }));

  const color = texture === 'glass' ? 'skyblue' : 'white';

  const textureLoader = useMemo(() => {
    const t = new TextureLoader().load("/images/" + texture + ".png")
    t.magFilter = NearestFilter
    t.minFilter = LinearMipMapLinearFilter
    return t
  }, [])


  return (
    <mesh
      castShadow
      ref={ref}
    >
      <boxBufferGeometry attach="geometry" />{' '}
      <meshStandardMaterial
        attach="material"
        // map={textures[texture]}
        map = {textureLoader}
        color={hover != null ? 'red' : color}
        opacity={texture === 'glass' ? 0.7 : 1}
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

export default memo(Surrounding, equalProps);
