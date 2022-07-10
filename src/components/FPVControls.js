import React, { useEffect, useRef } from 'react';
import { PointerLockControls as PointerLockControlsImpl } from 'three/examples/jsm/controls/PointerLockControls';
import { useThree, extend } from '@react-three/fiber';
import  useStarknetLib from  '/src/hooks/useStarknetLib';

extend({ PointerLockControlsImpl });

export const FPVControls = (props, {updateIsLocked}) => {
  const { gamemode} = useStarknetLib();

  const { camera, gl } = useThree();
  const controls = useRef();

  useEffect(() => {
    if(props&&props.gamemode == 'build'){
      let divTarget = document.createElement("div")
      divTarget.id = "divMaker"
      divTarget.style.width = "25px"
      divTarget.style.height = "25px"
      divTarget.style.background = "red"
      divTarget.style.position = "absolute"
      divTarget.style.top = "0"
      divTarget.style.left = "0"
      divTarget.style.right = "0"
      divTarget.style.bottom = "0"
      divTarget.style.margin = "auto"
      divTarget.style.zIndex= "99999"

      document.body.appendChild(divTarget)
    }
  }, []);

  useEffect(() => {
    if(props&&props.gamemode == 'tour'){
      document.addEventListener('click', () => {
        if(controls)
        {
          if(controls.current)
          {
            if(document.getElementById('canvasScene')) {
              controls.current.lock();
            // }else{
            //   if(document.getElementById('divMaker')){
            //     document.getElementById('divMaker').remove();
            //   }
            }
            //  updateIsLocked(true);
          }
        }
      });

    }else if (props&&props.gamemode=='build'){
      document.getElementById("divMaker").addEventListener('click', () => {
        if(controls)
        {
          if(controls.current)
          {
            if(document.getElementById('canvasScene')) {
              controls.current.lock();
            }else{
              if(document.getElementById('divMaker')){
                document.getElementById('divMaker').remove();
              }
            }
  
          }
        }
      });

    }
    

    // document.addEventListener('contextmenu', (e) => {
    //   e.preventDefault();
    //   if(controls)
    //   {
    //     if(controls.current)
    //     {
    //       updateIsLocked(false);
    //       controls.current.unlock();

    //     }
    //   }
    // });

    // if(controls.current){
    //   controls.current.addEventListener( 'lock', function () {
    //     document.getElementById("divMaker").style="display:block";
      
    //   } );
    //   controls.current.addEventListener( 'unlock', function () {
    //     document.getElementById("divMaker").style="display:block";
      
    //   } );
    // }

  }, []);




  return (
    <pointerLockControlsImpl
      ref={controls}
      args={[camera, gl.domElement]}
      {...props}

    />
  );
};
