import React,{useState,useEffect,useRef}from 'react';
import { useStore } from '/src/hooks/useStore';
import  useStarknetLib from  '/src/hooks/useStarknetLib';

const voyager_base_url = "https://goerli.voyager.online/tx/"
export default function ActionBox({updateComponent}) {
    const {starknetInstance,starknetConnected, activateGameMode,gamemode,
        starknetAddress,connectWallet,getLandInfoByCoords,
        ERC721_ownerOf,
        ERC721_updateTokenHash, 
        ERC721_tokenURI,
        get_short_hash,
        pinJsonIPFS,
        buildtokenid,
        getAspectUrl,
        provider_get_transaction,
        get_svg_image,
        parseMetadata} = useStarknetLib();

    const [tokenOwner, setTokenOwner] = useState()

    const [progress, setProgress] = useState('')
    const [tokenUrl, setTokenUrl] = useState('')
    const [txhash, setTxhash] = useState('')
    const [txhashshort, setTxhashshort] = useState('')
    const [txhashlink, setTxhashlink] = useState('')
    const [txstatus, setTxstatus] = useState('')

    const [textureitems, setTextureitems] = useState([])

    const [position] = useStore((state) => [
        state.position
    ]);


    const [cubes, addCube, removeCube, saveWorld,updateGround, batchInitialCube,resetCubes] = useStore((state) => [
        state.cubes,
        state.addCube,
        state.removeCube,
        state.saveWorld,
        state.updateGround,
        state.batchInitialCube,
        state.resetCubes
      ]);

   
   
    const landInfo = position&&position.current?getLandInfoByCoords(position.current[0],position.current[2]):null;  
    const tokenId = landInfo?landInfo.id:0;

  
    useEffect(() => {
        setTokenOwner("")
        loadOwner()
        async function loadOwner(){
            if(tokenId > 0){
                const ownerAddress = await ERC721_ownerOf(tokenId);
                setTokenOwner(get_short_hash(ownerAddress));
                const url = getAspectUrl(tokenId);
                setTokenUrl(url);
            }
        }   
      }, [tokenId])

     
      async function loopCheckStart(tx){

        var timer = setInterval(loopCheckTX, 10000); // every 10 seconds

        async function loopCheckTX() {
            if(txstatus == "ACCEPTED_ON_L2" || txstatus == "ACCEPTED_ON_L1") {
                setProgress("Done")
                clearInterval(timer);
                return;
            }
             //do stuff

             checkTxTokenID(tx);

        }
    }

    async function checkTxTokenID (tx){
        await provider_get_transaction(tx).then(async (res) =>{
            const hash_s = get_short_hash(res.transaction_hash);
            const hash_link = voyager_base_url + res.transaction_hash;

            setTxhashshort(hash_s);
            setTxhashlink(hash_link);
            setTxstatus(res.status);

            if(res.status === "ACCEPTED_ON_L2" || res.status === "ACCEPTED_ON_L1"){
                setProgress("Done")
            }
        });
    }

    const handleClick = async (e) => {
        // e.stopPropagation();   // prevent clicking into the canvas to activate FPV
    }
    const handleMenu = async (e) => {
        //reset

        if(document.getElementById('divMaker')){
            document.getElementById('divMaker').remove();
        }

        activateGameMode('');
    //    await connectWallet();
    }
 

    const handleReset = async (e) => {
        
        if(landInfo && tokenId>0)
        {
            //check ownership
            const ownerAddress = await ERC721_ownerOf(tokenId);

            if(ownerAddress!==starknetAddress)
            {
                console.log("You must be the land owner to update",ownerAddress[0],starknetAddress)
                return;
            }else{
                console.log("resetting")
                resetCubes();

            }

        }
    }


    const handleSaveProgress = async (e) => {
        
        console.log("saving progress onchain", cubes.length)

        if(landInfo && buildtokenid>0)
        {
            //check ownership
            const ownerAddress = await ERC721_ownerOf(buildtokenid);

            if(ownerAddress!==starknetAddress)
                {
                    console.log("You must be the land owner to update",ownerAddress[0],starknetAddress)
                    return;
                }
    
                // prepare metadata
                var metadata = {};
                metadata.name = "StarkWorld Land #" + buildtokenid;
                metadata.description = landInfo.w + "x" + landInfo.h + " sqm land at E" + landInfo.x + ":S" + landInfo.y;
                metadata.image = get_svg_image(landInfo.w,landInfo.h);
                metadata.attributes = {
                    "area":landInfo.w * landInfo.h,
                    "width":landInfo.w,
                    "depth":landInfo.h
                }
                metadata.components = cubes;

                setProgress('Generating Metadata');
                setTxhash('');

                // 1. pin metadata file  to IPFS
                await pinJsonIPFS(metadata)
                .then(async (res)=>{
                //    console.log(res)
                    let metahash = res.hash;
                    console.log("metahash",metahash)

                    setProgress('Saving onchain');
                    // 2. Update NFT MetadataHash
                    await ERC721_updateTokenHash(tokenId,metahash) 
                    .then(async (res)=>{
                        // console.log("metadata is updated in contract",res)

                        setTxhash(res.transaction_hash)
                        loopCheckStart(res.transaction_hash);


                    }).catch((error)=>{
                        console.log(error)
                    })   

                }).catch((error)=>{
                    console.log(error)
                })

        }
    }



    
    
  return (
    <div className="actionBoxContainer">
    <div id="actionBox" className="actionBox" onClick={handleClick}>

        <ul className='list-unstyled'>

        <li>
            <button className='primary' type="button" onClick={handleMenu} tabIndex={-1} >
            🏠 Menu
            </button>
        </li>
        
            <li>
                <p>
                    Land: {landInfo && ('#' + landInfo.id )  }</p>

                
                <p>Size: {landInfo && (landInfo.w + 'x' + landInfo.h)  }</p>
                <p>Owner: {tokenOwner && (tokenOwner)  }</p>
            </li>

       
        {gamemode == "build" && ( 
        <>
     
        <li><p>Objects: {cubes.length}</p></li>
        <li><p>Remaining: {150-cubes.length}</p></li>
        <li> -- --- ---</li>

        <li>
            <button className='success' type="button" onClick={handleSaveProgress} tabIndex={-1} >
            Save
            </button>
        </li>
        <li> -- --- ---</li>
        <li>
        <button className='error' type="button" onClick={handleReset} tabIndex={-1} >
            Reset
            </button>
        </li>
        
        </>)}

        <li> -- --- ---</li>
        <li><p className='progress'>{progress} </p></li>
            
            
            {txhash && (
                <li>
                <p className='progress'>Hash: <a href={txhashlink} target="_blank"  rel="noreferrer" tabIndex={-1}>{txhashshort}</a></p>
                <p className='progress'>Status: {txstatus}</p>
                <p className='progress'>Confirmation:  {progress == 'Done'? " Done" :(<span>...<span className='waiting'>⌛</span></span>)}
                </p>
                </li>

            )}

        </ul>







    
    </div>
    <style jsx>{`
        .actionBox{
          position: fixed;
          top: 10px;
          right: 10px;
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
