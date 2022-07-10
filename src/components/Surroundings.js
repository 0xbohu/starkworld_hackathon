import React from 'react';
import { useStore } from '../hooks/useStore';
import SurroundingGroup from './SurroundingGroup';

export default function Surroundings(props) {

  const [ surroundings] = useStore((state) => [
    state.surroundings,
  ]);


  return surroundings && surroundings.map((cube) => {
    return (
      <SurroundingGroup
      key={cube.group}
      components={cube.components}
      />
    );
  })

}
