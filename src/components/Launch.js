import React,{useState,useEffect}from 'react';
import { useStore } from '/src/hooks/useStore';
import  useStarknetLib from  '/src/hooks/useStarknetLib';


const voyager_base_url = "https://goerli.voyager.online/tx/"
export default function Launch({activatePlay,activateBuild,activateTest}) {
    const {starknetConnected,
        starknetAddress,connectWallet,getLandInfoByCoords,
        ERC721_ownerOf,
        ERC721_mint,
        ERC721_nextTokenId,
        provider_get_transaction,
        get_short_hash,
        parse_tx_events} = useStarknetLib();

    const [nexttokenid, setNexttokenid] = useState('')

    const [txhash, setTxhash] = useState('')
    const [txhashshort, setTxhashshort] = useState('')
    const [txhashlink, setTxhashlink] = useState('')
    const [txstatus, setTxstatus] = useState('')
    const [txtokenid, setTxtokenid] = useState('')
    const [buildtokenid, setBuildtokenid] = useState('')



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


    async function load_next_token_id() {
            const res = await ERC721_nextTokenId().then((res)=>{
                setNexttokenid(res)
            }).catch((err)=>{
                setNexttokenid("")
            })
    }

    async function loopCheckStart(tx){

        var timer = setInterval(loopCheckTX, 10000); // every 10 seconds

        async function loopCheckTX() {
            if(txstatus == "ACCEPTED_ON_L2" || txstatus == "ACCEPTED_ON_L1") {
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
                await parse_tx_events(res.events).then((tid) =>{
                    setTxtokenid(tid);
                })
            }
        });
    }
    
    const handleConnectWallet = async (e) => {
        e.stopPropagation();
        
        console.log("connect")

       await connectWallet();
    }

    const handleActivatePlay = async (e) => {
        e.stopPropagation();
        activatePlay();
    }

    const handleMint = async (e) => {
        e.stopPropagation();
       await load_next_token_id();
        const res = await ERC721_mint().then((res)=>{
            // console.log(res)
            setTxhash(res.transaction_hash)
            loopCheckStart(res.transaction_hash);
        }).catch((err)=>{
            console.log(err)
        })
    }

    const handleBuild = async (e) => {
        e.stopPropagation();

        if(isNaN(buildtokenid)){
            console.log(buildtokenid + " is not a valid token id <br/>");
            return
         }else{

             //check ownership
            const ownerAddress = await ERC721_ownerOf(buildtokenid);

            if(ownerAddress!==starknetAddress)
            {
                console.log("You must be the land owner to update. Current Owner",ownerAddress)
                return;
            }else{
                activateBuild(buildtokenid);
            }
           
         }
    }

    const handleInputChange= (e) => {

        setBuildtokenid(e.target.value)

    }    
    
  return (
    <main>

<h1 className="title">
          Welcome to StarkWorld
        </h1>

        <p className="description">
          A virtual world built on Starknet
        </p>
        

        {!starknetConnected ? (
             <p className="description"><button className='primary' type="primary" onClick={handleConnectWallet} tabIndex={-1} >
             Connect Wallet
             </button></p>
        ):
        <>
        <div className="grid-container">
        <div className="grid">
         <div className="card">
        Movement: W/S/D/A<br/>
        Add Object: Click<br/>
        Remove Object: Option + Click<br/>
        Hide Cursor: Click red square<br/>
        Show Cursor: Escape Key<br/>   
        </div>
        </div>
            <div className="grid">
                <div className="card">
                    <h3> 
                        <button className='primary' type="button" onClick={handleActivatePlay} tabIndex={-1} >
                        Tour
                        </button></h3>
                    <p>Just look around</p>
                
                </div>
            </div>
            <div className="grid">
                <div  className="card">
                    <h3><button className='success' type="button" onClick={handleMint} tabIndex={-1} >
                        Mint
                        </button></h3>
                    <p>Mint a new land</p>
                    {nexttokenid && (<p>Next ID: {nexttokenid}</p>)}
                </div>
            </div>
            <div className="grid">

                <div  className="card">
                    <h3><button className='error' type="button" onClick={handleBuild} tabIndex={-1} >
                        Build
                        </button></h3>
                    <p>
                    <input type="text" tabIndex={-1} placeholder="Your land ID"
                     value={buildtokenid} onChange={handleInputChange} />
                    </p>
                    
                </div>
            </div>

            </div>  
           
        {txhash && 
         <div className="grid-container">
         <div className="grid">
             <div className="card">
                 <p>Hash: <a href={txhashlink} target="_blank"  rel="noreferrer" tabIndex={-1}>{txhashshort}</a></p>
                 <p>Status: {txstatus}</p>
                 <p>Mint:  {txtokenid 
                            ?((txtokenid) + " ✅")
                            :(<span>Waiting...<span className='waiting'>⌛</span></span>)}</p>
                 </div>
             </div>
         </div>
        }
        </>
    
    
    
    }
       
</main>


  );
 
};
