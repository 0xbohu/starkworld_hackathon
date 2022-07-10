import React from 'react';
import { useStore } from '../hooks/useStore';
import Surrounding from './Surrounding';

export default function SurroundingGroup(props) {

  return props.components && props.components.map((cube) => {
    return (
      <Surrounding
        key={cube.key}
        texture={cube.texture}
        position={cube.pos}
      />
    );
  })

}
