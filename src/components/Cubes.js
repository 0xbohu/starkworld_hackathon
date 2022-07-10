import React from 'react';
import { useStore } from '../hooks/useStore';
// import { useInterval } from '../hooks/useInterval';
import Cube from './Cube';

export default function Cubes(props) {

    const [cubes,addCube, removeCube] = useStore((state) => [
       state.cubes,  
       state.addCube,
        state.removeCube,
      ]);

  return cubes && cubes.map((cube) => {
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
