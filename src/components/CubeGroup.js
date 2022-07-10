import React from 'react';
import { useStore } from '../hooks/useStore';
// import { useInterval } from '../hooks/useInterval';
import Cube from './Cube';

export default function CubeGroup(props) {

    const [addCube, removeCube] = useStore((state) => [
        state.addCube,
        state.removeCube,
      ]);

  return props.components && props.components.map((cube) => {
    return (
      <Cube
        key={cube.key}
        texture={cube.texture}
        position={cube.pos}
        addCube={addCube}
        removeCube={removeCube}
      />
    );
  })

}
