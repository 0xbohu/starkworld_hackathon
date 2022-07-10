
import React, { useState,useEffect } from 'react';
import { Canvas } from '@react-three/fiber';
import { useStore } from '/src/hooks/useStore';
import  useStarknetLib from  '/src/hooks/useStarknetLib';

import { Sky } from '@react-three/drei';
import { Physics } from '@react-three/cannon';
import { Ground } from '/src/components/Ground';
import { Player } from '/src/components/Player';
import {FPVControls} from '/src/components/FPVControls';
import {Landscape} from '/src/components/Landscape';
import Cubes from '/src/components/Cubes';


export default function Build(props) {
  const {buildtokenid, getNearbyLandsByCoords,ERC721_tokenURI,parseMetadata} = useStarknetLib();
  const [mapdata, setMapdata] = useState([]);
  const [mapdataid, setMapdataid] = useState('');


  const [updating, setUpdating] = useState(false);
  const [landids, setLandids] = useState([]);


  const [lands, setLands] = useState([]);

  const playerInitialPosition = props.initialPosition;


  const [cubes, position,surroundings,updateSurroundings,
    removeSurroundings,
    batchInitialCube,batchLoadCube,addCube,removeCube] = useStore((state) => [
      state.cubes,  
      state.position,
      state.surroundings,
      state.updateSurroundings,
      state.removeSurroundings,
      state.batchInitialCube,
      state.batchLoadCube,
      state.addCube,
      state.removeCube, 
  ]);

  
  const position_str = position&&position.current? position.current[0] + ":" + position.current[2]:'';

  const [ground] = useStore((state) => [
    state.ground
  ]);

  const groundKey = "ground-" + ground.join('-'); // this is to force the ground to update when land changes
  
  
  useEffect(() => {

    const mdata = position&&position.current?
    getNearbyLandsByCoords(position.current[0],position.current[2])
    :getNearbyLandsByCoords(playerInitialPosition[0],playerInitialPosition[2]);  
    setMapdata(mdata)

    var oldtokenIdstr = mapdataid
    var tokenIdstr = '';
    mdata.forEach(node => {
      tokenIdstr+= node.id.toString() + ","
    })


    setMapdataid(tokenIdstr);
   
    if(tokenIdstr!==oldtokenIdstr)  // new fetech
    {
      // console.log("updating env...")
      load_lands()
    }

    async function load_lands() {

      const delta_adding_lands = [buildtokenid];

      if(delta_adding_lands.length > 0){
        var arr_components = [];
          await Promise.all(
            delta_adding_lands.map(async (node) => {
              console.log("fetch", node)
              const tokenUri = await ERC721_tokenURI(node).then(async (res)=>{
    
                if(node>0)
                {
                    if(res !== "https://momenft.mypinata.cloud/ipfs/"){
                    const metadata = await parseMetadata(res);
                    const components = metadata.data.components.map( 
                      (data, index) => ({...data, group:node}) );

                      console.log(components.length)
                    arr_components.push(...components)
                }
              }
                  
              }).catch((err)=>{
                  console.log(err)
              })
            })
          );
        
          batchInitialCube(arr_components);
      } // end of adding new components
    }

  }, [buildtokenid])


    return (

        <Canvas id="canvasScene"
        >
          <Sky sunPosition={[100, 20, 100]} />
          <ambientLight intensity={0.25} />
          <pointLight castShadow intensity={0.7} position={[100, 100, 100]} />
          <Physics gravity={[0, -30, 0]}>
            <Ground key={groundKey} />
            <Player position={playerInitialPosition}
             />
            <Cubes />
            <FPVControls 
             {...props}/>
            <Landscape />
          </Physics>
        </Canvas>
    );

}