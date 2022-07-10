
import React, { useMemo,useState,useEffect } from 'react';
import * as THREE from 'three'
import { usePlane } from '@react-three/cannon';
import {
  TextureLoader,
  RepeatWrapping,
  NearestFilter,
  LinearMipMapLinearFilter,
} from 'three';
import { Image,Html, Billboard,useCursor } from '@react-three/drei'

import { Reflector, Text, useTexture, useLoader } from "@react-three/fiber";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader";

export const VideoText = (props) => { 
    const [video] = useState(() => Object.assign(document.createElement('video'), { src: 'https://cdn-testnet.aspect.co/assets/e191b847-5ea7-46bf-bf93-c92390b08ac8/animations/QmRQes23L19vj7JQAqr5PcbStDHUsWp7k9g4woFpWno87j',
     crossOrigin: 'Anonymous', loop: true }))
    useEffect(() => void (video.play()), [video])
    return (
      <Text 
    //   font="/Inter-Bold.woff" 
      fontSize={3} letterSpacing={-0.06} {...props}>
        drei
        <meshBasicMaterial toneMapped={false}>
          <videoTexture attach="map" args={[video]} encoding={THREE.sRGBEncoding} />
        </meshBasicMaterial>
      </Text>
    )
  }