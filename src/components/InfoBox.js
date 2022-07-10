import React, {useState,useEffect} from 'react';
import { useStore } from '/src/hooks/useStore';
import  useStarknetLib from  '/src/hooks/useStarknetLib';
useState

export default function InfoBox() {
    const {gamemode,starknetAddress,get_short_hash} = useStarknetLib();
    const [position,setTexture] = useStore((state) => [
      state.position,
      state.setTexture
  ]);
    const [selectedtexture, setSelectedtexture] = useState('')
    const [textureitems, setTextureitems] = useState([])
    const coords = position&&position.current?  returnCoordLiteral (position.current[0],position.current[2]):""


    function returnCoordLiteral(x,y){
      var result = ""
      if(x>=0){
        result += "E " + Math.abs(x.toFixed(2)).toString()
      }else{
        result += "W " + Math.abs(x.toFixed(2)).toString()
      }
      result += " "
      if(y>=0){
        result += "S " + Math.abs(y.toFixed(2)).toString()
      }else{
        result += "N " + Math.abs(y.toFixed(2)).toString()
      }
      return result;
    }

     // setup texture
     useEffect(() => {

      if(gamemode === "build"){
          var arr = []

          arr.push("dirt")
          arr.push("grass")
          arr.push("glass")
          arr.push("wood")
          arr.push("log")

          for (var i=1; i <= 25; i++) {
              arr.push("b" + i.toString())
          }

          for (var i=1; i <= 25; i++) {
              arr.push("t" + i.toString())
          }

          for (var i=1; i <= 25; i++) {
              arr.push("r" + i.toString())
          }

          for (var i=1; i <= 25; i++) {
              arr.push("g" + i.toString())
          }

          for (var i=1; i <= 25; i++) {
              arr.push("w" + i.toString())
          }
      
          setTextureitems(arr)
      }
    
    }, [])

    const handleSelectTexture=(key)=> {
      setTexture(key)
      setSelectedtexture(key)
  }


    const handleClick = async (e) => {
        // e.stopPropagation();   // prevent clicking into the canvas to activate FPV
    }

  return (
    <div className="infoBoxContainer">
    <div className="infoBox" onClick={handleClick}>

      <ul className='list-unstyled'>
      
         {starknetAddress && (
            <li><p>Welcome {starknetAddress?get_short_hash(starknetAddress):""}</p></li>
        )}
        <li><p>{coords}</p></li>
       
        {gamemode == "build" && (
          <>
         <li  className="info"> Movement: W/S/D/A</li>
        <li className="info"> Add objects: Click</li>
        <li  className="info"> Remove objects: Option + Click</li>
        <li  className="info"> Hide Cursor: Click Red Square</li>
        <li  className="info"> Show Cursor: Escape Key</li>
        </>
        )}

        {gamemode == "tour" && (
          <>
         <li  className="info"> Movement: W/S/D/A</li>
        <li  className="info"> Hide Cursor: Left Click </li>
        <li  className="info"> Show Cursor: Escape Key</li>
        </>
        )}

      </ul>

        <div className='texture-container'>
          {textureitems ? (
                textureitems.map((item,i) => {

                  const selected = selectedtexture === item? "texture-item selected":"texture-item"
                  return (
                <button key={i}  className={selected} 
                onClick={e => handleSelectTexture(item.toString())}
                >
                  <img src={"/images/" + item.toString()+ ".png"} 

                  tabIndex={-1}
                  />
                  </button>
                )})
              ) : (
                <mesh></mesh>
              )}

          </div>
    </div>

   



<style jsx>{`
        .infoBox{
          position: fixed;
          top: 10px;
          left: 10px;
          z-index: 1000;
          background-color:#bac9d9;
          border-radius: 15px;
          filter: alpha(opacity=60);
          min-width:200px;
          max-width:200px;
          min-height:200px;
          max-height:500px;
          overflow:scroll;
            /* IE */
            -moz-opacity: 0.8;
            /* Mozilla */
            opacity: 0.8;
        }
      `}</style>



      </div>
  );
};
