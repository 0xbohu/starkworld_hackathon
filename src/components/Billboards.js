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

import useStarknetLib from  '/src/hooks/useStarknetLib';





export const Billboards = (props) => {
  const [hovered, set] = useState()

  const {fetchAssetAspect} = useStarknetLib();


  const {getNearbyLandsByCoords,ERC721_tokenURI,parseMetadata,get_short_hash} = useStarknetLib();

  
  useCursor(hovered, /*'pointer', 'auto'*/)


 const [assetdata, setAssetdata] = useState(null)
 const [pricetag, setPricetag] = useState('')


  const [ref] = usePlane(() => ({ rotation: [-Math.PI / 2, 0, 0], ...props}));

  const texture = useMemo(() => {
    const t = new TextureLoader().load("/images/glass.png")
    t.wrapS = RepeatWrapping
    t.wrapT = RepeatWrapping
    t.repeat.set(500, 500)
    return t
  }, [])

 
  texture.magFilter = NearestFilter;
  texture.minFilter = LinearMipMapLinearFilter;
  texture.wrapS = RepeatWrapping;
  texture.wrapT = RepeatWrapping;
  texture.repeat.set(500, 500);


 

  useEffect( () => {
    loadAsset();

    async function loadAsset(){
      const asset = await fetchAssetAspect("0x0266b1276d23ffb53d99da3f01be7e29fa024dd33cd7f7b1eb7a46c67891c9d0","2350076320186443877739336848108449226345699072742303847771022788174320500736")
      setAssetdata(asset.data);

      if(asset.data){
        if(asset.data.best_bid_order){
          try{
           const ptag = (asset.data.best_bid_order.payment_amount/1000000000000000000).toString() + " eth";
           setPricetag(ptag)

          }catch(e){

          }

        }
      }


     
      

    }
   
  }, []);

  const default_obj = "https://api.briq.construction/get_model/0x53218976a09493f540741905220c5ccaaeb95005db417ba4000000000000000.glb"
  const gltf = useLoader(GLTFLoader,assetdata?assetdata.animation_url_copy:default_obj)

  return (
      <mesh
        ref={ref}
        receiveShadow
      >
        <Billboard
            follow={true}
            lockX={true}
            lockY={true}
            lockZ={false}  // Lock the rotation on the z axis (default=false)
            position={[5, -68, -5]}
            >
          {
           gltf && <primitive object={gltf.scene}
               scale={0.05} 
                rotation={[0, 0, Math.PI / 1]} 
                position={[5, 1, 10]}
             />
            }
             <Html 
                scale={1.5} 
                rotation={[Math.PI / 2, 0, 0]} 
                position={[5, 1, 6]}
                transform 
                occlude
                >
                <div className="annotation"> 
                <span style={{ fontSize: '0.1em' }}> {assetdata&& (pricetag)} {" "}</span>
                <span style={{ fontSize: '0.1em' }}><a href={assetdata?assetdata.aspect_link:"#"}
                    target="_blank"
                    rel="noreferrer"
                    tabIndex={-1}
                    >Bid on Aspect</a></span>
                </div>
                <div className="annotation"> 
                <span style={{ fontSize: '0.1em' }}>{assetdata&& (assetdata.name)} </span>
                </div>
                <div className="annotation">
                <span style={{ fontSize: '0.1em' }}>{assetdata&& (assetdata.description)} </span>
                </div> 
                <div className="annotation"> 
                <span style={{ fontSize: '0.1em' }}>Owner {assetdata&& (get_short_hash(assetdata.owner.account_address))}</span>
                </div>
               
                
                </Html>
      </Billboard>



      </mesh>
  );
};
