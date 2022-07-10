
import React, { useState,useEffect } from 'react';
import { Canvas } from '@react-three/fiber';
import { useStore } from '/src/hooks/useStore';
import  useStarknetLib from  '/src/hooks/useStarknetLib';
import { StarknetProvider } from '/src/@core/context/starknetContext'

import { Sky } from '@react-three/drei';
import { Physics } from '@react-three/cannon';
import { Player } from '/src/components/Player';
import {FPVControls} from '/src/components/FPVControls';
import { World } from '/src/components/World';
import {Landscape} from '/src/components/Landscape';
import {Billboards} from '/src/components/Billboards';
import Surroundings from '/src/components/Surroundings';



export default function Scene(props) {
  const {getNearbyLandsByCoords,ERC721_tokenURI,parseMetadata} = useStarknetLib();
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

  // const [ground] = useStore((state) => [
  //   state.ground
  // ]);

  // const groundKey = "ground-" + ground.join('-'); // this is to force the ground to update when land changes
  
  
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
      
      // #1, set the lands within range, to render lands
      var arr_oldlands = lands;
      var arr_newlands = [];

      var arr_oldlandids = landids;
      var arr_newlandids = [];

      var surrs = [];
      var new_surrs = [];
      mdata.forEach(node => {
        arr_newlands.push(["land-" + node.id.toString(),node.x,0,node.y,node.w,node.h,node.id])  // node.y is placed in z
        arr_newlandids.push(node.id);
        
        surrs.push(node.id);
      })
      const delta_adding_lands = arr_newlandids.filter(x => !arr_oldlandids.includes(x))
      const delta_deleting_lands = arr_oldlandids.filter(x => !arr_newlandids.includes(x))


      // console.log("delta_deleting_lands",delta_deleting_lands)
      // console.log("delta_adding_lands",delta_adding_lands)

      setLands(arr_newlands) // set land objects for rendering
      setLandids(arr_newlandids) // set land ids for keep tracking
      removeSurroundings(delta_deleting_lands)

      // #2, now only get the components for new adding lands
      if(delta_adding_lands.length > 0){
        var arr_components = [];
        // if(!updating)
        // {
          // setUpdating(true)
          await Promise.all(
            delta_adding_lands.map(async (node) => {
            // new_surrs.forEach(async(node) => {
              console.log("fetch", node)
              const tokenUri = await ERC721_tokenURI(node).then(async (res)=>{
    
                if(node>0)
                //(node.id == 2 
                  // || node.id == 1 || node.id == 2
                {
                if(res !== "https://momenft.mypinata.cloud/ipfs/"){
                    const metadata = await parseMetadata(res);
                    const components = metadata.data.components.map( 
                      (data, index) => ({...data, group:node}) );
                    arr_components.push({group:node, components:[...components]})
                }
              }
                  
              }).catch((err)=>{
                  console.log(err)
              })
            })
          );

          updateSurroundings(arr_components);
      } // end of adding new components
    }

  }, [position_str])

  // useEffect(() => {

    
  // }, [mapdataid])

    return (

        <Canvas id="canvasScene"
        >
          <Sky sunPosition={[100, 20, 100]} />
          <ambientLight intensity={0.25} />
          <pointLight castShadow intensity={0.7} position={[100, 100, 100]} />
          <Physics gravity={[0, -30, 0]}>
            {/* <Ground key={groundKey} /> */}
            <Player position={playerInitialPosition}
             />
            {/* <Cubes cubes={cubes} /> */}
            {/* render world map */}
            {lands ? (
              lands.map((land) => {
                return (
                <World key={land[0]} position={[land[1], land[2], land[3]]} x={land[4]} y={land[5]} tid={land[6]} />
              )})
            ) : (
              <mesh></mesh>
            )}
            <Surroundings />
            <FPVControls 
            // updateIsLocked={updateIsLocked} 
             {...props}/>
             <StarknetProvider>
            <Billboards position={[15, 2, 15]} />
            </StarknetProvider>
            
            <Landscape />
          </Physics>
        </Canvas>
    );

}