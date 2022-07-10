import React, {useState} from 'react';
import dynamic from 'next/dynamic'
import InfoBox from '/src/components/InfoBox';
import ActionBox from '/src/components/ActionBox';
import Launch from '/src/components/Launch';
import { useStore } from '/src/hooks/useStore';
import useStarknetLib from  '/src/hooks/useStarknetLib';

const Scene = dynamic(
    () => import('./Scene'),
    { ssr: false }
  )
  const Build = dynamic(
    () => import('./Build'),
    { ssr: false }
  )
  
export default function App() {

  const {gamemode,activateGameMode,setActiveLocationTokenId,getLandInfoById} = useStarknetLib();

  const [updateGround] = useStore((state) => [
    state.updateGround,
  ]);

  const [initialPosition, setInitialPosition] = useState([30, 0, 100])
 
  function activatePlay () {
    activateGameMode("tour")
  }

  function activateBuild (tokenId) {
    setActiveLocationTokenId(tokenId)
    activateGameMode("build")


    console.log(tokenId)

    const landInfo = getLandInfoById(tokenId);

    if(landInfo && tokenId>0)
    {
      setInitialPosition([landInfo.x,0,landInfo.y])
      updateGround(landInfo.x,0.5,landInfo.y,landInfo.w,landInfo.h)
    }
    
    
  }

    return( 

      <>
      {(gamemode==="tour" || gamemode==="build") ? (
        <>
        {gamemode==="tour" && (
           <>
          <Scene gamemode={gamemode} initialPosition={initialPosition} />
         
          </>
        )}
        {gamemode==="build" && (
           <>
          <Build onContextMenu={(e) => console.log(e)}  gamemode={gamemode} initialPosition={initialPosition} />
          </>
        )}

        <InfoBox  />
        <ActionBox />
       </>
      ) : (

        <Launch activatePlay={activatePlay} activateBuild={activateBuild}  />
       
      )}
    </>
    
    )
}