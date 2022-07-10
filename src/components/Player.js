import React, { useEffect, useRef } from 'react';
import { useSphere } from '@react-three/cannon';
import { Vector3 } from 'three';
import { useThree, useFrame } from '@react-three/fiber';
import { useKeyboardControls } from '../hooks/useKeyboardControls';
import { useStore } from '../hooks/useStore';

const SPEED = 5;

export const Player = (props) => {
  const [setPosition] = useStore((state) => [state.setPosition]);
  
  const { camera } = useThree();
  const { moveForward, moveBackward, moveLeft, moveRight, jump } =
    useKeyboardControls();
  const [ref, api] = useSphere(() => ({
    mass: 1,
    type: 'Dynamic',
    ...props,
  }));

  const velocity = useRef([0, 0, 0]);
  useEffect(() => {
    api.velocity.subscribe((v) => (velocity.current = v));
  }, [api.velocity]);

  const pos = useRef([0, 0, 0]);
  useEffect(
    () => 
    api.position.subscribe((v) => (pos.current = v))
    , [api.position]);

    // useEffect(() => {
    //   camera.position.copy(
    //     new Vector3(props.position[0], props.position[1]+1, props.position[2])
    //   );
    //   console.log(pos.current)
    // }, []);

  useFrame(() => {
    camera.position.copy(
      new Vector3(pos.current[0], pos.current[1]+3, pos.current[2])
    );

    const direction = new Vector3();

    const frontVector = new Vector3(
      0,
      0,
      (moveBackward ? 1 : 0) - (moveForward ? 1 : 0)
    );
    const sideVector = new Vector3(
      (moveLeft ? 1 : 0) - (moveRight ? 1 : 0),
      0,
      0
    );

    direction
      .subVectors(frontVector, sideVector)
      .normalize()
      .multiplyScalar(SPEED)
      .applyEuler(camera.rotation);
    

    api.velocity.set(direction.x, velocity.current[1], direction.z)
    
    if(moveBackward||moveForward||moveLeft||moveRight){
      setPosition(pos)
    }

    if (jump && Math.abs(velocity.current[1].toFixed(2)) < 0.05) {
      api.velocity.set(velocity.current[0], 8, velocity.current[2]);
    }
  });
  return (
    <>
      {/* <FPVControls /> */}
      <mesh ref={ref}>
      </mesh>
    </>
  );
};
