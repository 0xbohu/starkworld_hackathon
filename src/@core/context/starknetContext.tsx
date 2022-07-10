
import React, { createContext, useState,useRef } from "react";

// ** Starknet and Argent
import { connect, IStarknetWindowObject } from "@argent/get-starknet"
import intersects from  'intersects';
import {mapData} from '../../configs/map.js';
import { number } from 'starknet';

interface IStarknetContext {
    starknetAddress: string
    starknetConnected: boolean
    gamemode:string
    buildtokenid:number
    activateGameMode:(gm:string)=> any
    setActiveLocationTokenId:(tokenId:number)=> any
    getAspectUrl:(tokenId:number)=> any

    connectWallet:() => any
    
    shortStringToBigIntUtil:(originalString:string) => BigInt
    getLandInfoByCoords:(x:number, y:number) => any
    getLandInfoById:(id:number)=> any
    getNearbyLandsByCoords:(x:number, y:number) => any
    convertStringToShortStringArray:(originalString:string) => string[]
    ERC721_tokenURI:(tokenId:number)=> any
    ERC721_ownerOf:(tokenId:number)=> any   
    ERC721_nextTokenId:()=> any
    ERC721_updateTokenHash:(tokenId:number,metahash:string)=> any
    ERC721_mint:()=> any

    provider_get_transaction:(hash:string)=> any
    get_short_hash:(hash:string)=> any

    parse_tx_events:(events:any)=> any

    parseMetadata:(url:string)=> any

    get_svg_image:(x:number,y:number) => any

    pinJsonIPFS:(metadata:any) => any
    fetchAssetAspect:(contract:string, tokenid:string) => any
}

interface BigIntArray {
    elements : BigInt[];
 }
type payloadPinJson = {
    hash: string;
};

type cairoContractData = {
    contractAddress: string;
    entrypoint:string;
    calldata:string[]
};


export const aspectBaseUrl = "https://testnet.aspect.co/asset/"
export const contractAddress = "0x0449b6ee7e9a4d16471b75ed0aade9fc32f03f45ec7286440977dc2bbd4cdd0e";
export const SHORT_STRING_MAX_CHARACTERS = 31;

export const StarknetContext = createContext<IStarknetContext>({} as IStarknetContext);

export const StarknetProvider = ({ children } : { children : React.ReactElement }) => {
    const [starknetInstance, setStarknetInstance] = useState<any | null>(null);
    const [starknetConnected, setStarknetConnected] = useState (false);
    const [starknetAddress, setStarknetAddress] = useState ('');

    const [buildtokenid, setBuildtokenid] = useState (0);
    const [gamemode, setGamemode] = useState ('');
    
    // connect user wallet
    const connectWallet = async () => {

        const starknet:IStarknetWindowObject| undefined = await connect();
 
        if(starknet)
        {
            setStarknetInstance(starknet);
        }
        
    
        if (!starknet) {
            console.log('Wallet is not connected')
            setStarknetConnected(false);
        }else{
    
        // await to connect
        await starknet.enable();
    
        // Check if connection was successful
        if(starknet.isConnected) {
            setStarknetConnected(true);
            console.log('Wallet is connected')
            // load starknet account address
            const userAddress = starknet.account.address;

            setStarknetAddress(userAddress);
    
        } else {
            // In case the extension wasn't successfully connected you still have access to a starknet.js Provider to read starknet states and sent anonymous transactions
            
            setStarknetConnected(false);
    
        }
        }
    
    }

    const activateGameMode =  (gm:string) => {
        setGamemode(gm)
    }

     // pin Metadata Json to IPFS
     const pinJsonIPFS = async (metadata:any) => {

        return  new Promise(async function (resolve, reject) {

            try{
                if(!metadata){
                    reject({"error":"Metadata is invalid"})
                }else{
                    await fetch('/api/pinjson', {
                        method: 'POST',
                        headers: {
                        'Content-Type': 'application/json',
                        },
                        body: JSON.stringify(metadata),
                    })
                    .then(async (res) =>res.json())
                    .then((data) => {
                        if(data.data.IpfsHash){
                            resolve({"hash":data.data.IpfsHash.toString()})
                        }
                    }).catch((e)=>{
                        console.log(e)
                    })
                }
            }catch(err){
                reject({"error":err})
            }
        })
    }

    // fetchAssetAspect
    const fetchAssetAspect = async (contract:string, tokenid:string) => {

        return  new Promise(async function (resolve, reject) {

            try{
                if(contract && tokenid){
                    var payload = {contract:contract,tokenid:tokenid}
                    await fetch('/api/fetchasset', {
                        method: 'POST',
                        headers: {
                        'Content-Type': 'application/json',
                        },
                        body: JSON.stringify(payload),
                    })
                    .then((res) => res.json())
                    .then((data) => {
                        resolve(data);
                    })
                }
            }catch(err){
                reject({"error":err})
            }
        })
    }

    const setActiveLocationTokenId = (tokenId:number) => {
        setBuildtokenid(tokenId)
    }

    // *******************
    // StarkWorld Contract
    // *******************

    const ERC721_ownerOf = (tokenId:number) => {

        return  new Promise(async function (resolve, reject) {

            try{
                if(!tokenId){
                    console.log('tokenId is invalid')
                    reject({"error":"tokenId is invalid"})
                }else{
                   
                    const starknet = starknetInstance;
                    if(!starknet)
                    {
                        console.log('Starknet instance is invalid')
                        reject({"error":"Starknet instance is invalid"})
                    }else{

                        let calldataArray: string[] = [];

                        calldataArray.push(BigInt(tokenId).toString())
                        calldataArray.push(BigInt(0).toString())

                        const callObject: cairoContractData = {
                            contractAddress:contractAddress,
                            entrypoint:"ownerOf",
                            calldata: calldataArray
                        }

                        const rs = await starknet.provider.callContract(callObject)
                        .then((res:any)=>{
                            if(res.result)
                            {
                                resolve(res.result[0])
                            }else{
                                reject({"error":res.message})
                            }
                        })
                        .catch((err)=>{
                            reject({"error":err})
                        })
                    }
                }
            }catch(err){
                console.log(err)
                reject({"error":err})
            }
        })
    }


    const ERC721_tokenURI = (tokenId:number) => {

        return  new Promise(async function (resolve, reject) {

            try{
                if(!tokenId){
                    console.log('tokenId is invalid')
                    reject({"error":"tokenId is invalid"})
                }else{
                   
                    const starknet = starknetInstance;
                    if(!starknet)
                    {
                        console.log('Starknet instance is invalid')
                        reject({"error":"Starknet instance is invalid"})
                    }else{

                        let calldataArray: string[] = [];

                        calldataArray.push(BigInt(tokenId).toString())
                        calldataArray.push(BigInt(0).toString())

                        const callObject: cairoContractData = {
                            contractAddress:contractAddress,
                            entrypoint:"tokenURI",
                            calldata: calldataArray
                        }

                        const rs = await starknet.provider.callContract(callObject)
                        .then((res:any)=>{
                            resolve(feltArrToStr(res.result))
                        })
                        .catch((err)=>{
                            reject({"error":err})
                        })
                    }
                }
            }catch(err){
                console.log(err)
                reject({"error":err})
            }
        })
    }


    const get_short_hash  = (hash:string) => {
      return hash.substring(0, 5) + '...' + hash.slice(hash.length - 5);
    }

    
    const ERC721_updateTokenHash = (tokenId:number,metahash:string) => {


        return  new Promise(async function (resolve, reject) {

            try{
                if(!metahash){
                    reject({"error":"Metadata hash is invalid"})
                }else{

                    const arr = convertStringToShortStringArray(metahash);

                    if(arr.length <=0)
                    {
                        reject({"error":"Metadata hash array is invalid"})
                    }

                   
                    const starknet = starknetInstance;
                    if(!starknet)
                    {
                        reject({"error":"Starknet instance is invalid"})
                    }else{

                        let calldataArray: string[] = [];

                        //token_id

                        calldataArray.push(BigInt(tokenId).toString())
                        calldataArray.push(BigInt(0).toString())

                         //meta hash
                        calldataArray.push(arr.length.toString())
                        arr.forEach(element => {
                            var bigIntElem = shortStringToBigIntUtil(element);
                            calldataArray.push(bigIntElem.toString())
                        }
                        );
                        
                        const callObject: cairoContractData = {
                            contractAddress:contractAddress,
                            entrypoint:"updateTokenHash",
                            calldata: calldataArray
                        }

                        const rs = await starknet.account.execute([callObject])
                        .then((res:any)=>{
                        resolve(res);
                        })
                        .catch((err:any)=>{
                            reject({"error":err})
                        })
                      

                    }
                }

            }catch(err){
                reject({"error":err})
            }
        })
    }


    const ERC721_mint = () => {


        return  new Promise(async function (resolve, reject) {

            try{
                const starknet = starknetInstance;
                if(!starknet)
                {
                    reject({"error":"Starknet instance is invalid"})
                }else{

                    let calldataArray: string[] = [];

                    const callObject: cairoContractData = {
                        contractAddress:contractAddress,
                        entrypoint:"mint",
                        calldata: calldataArray
                    }

                    const rs = await starknet.account.execute([callObject])
                    .then((res:any)=>{
                        resolve(res);
                    })
                    .catch((err:any)=>{
                        reject({"error":err})
                    })

                }

            }catch(err){
                reject({"error":err})
            }
        })
    }


    const get_svg_image = (x:number,y:number) =>{
        const imgsrc = new Buffer( '<svg xmlns="http://www.w3.org/2000/svg" width="' + x*5 + '" height="' + y*5 + '" viewBox="0 0 ' + x*5 + ' ' + y*5 + '"><rect fill="#ddd" width="' + x*5 + '" height="' + y*5 + '"/><text fill="rgba(0,0,0,0.5)" font-family="sans-serif" font-size="30" dy="10.5" font-weight="bold" x="50%" y="50%" text-anchor="middle">' + x.toString() + '×' + y.toString() + '</text></svg>').toString( "base64" );
        return 'data:image/svg+xml;base64,' + imgsrc;
    }

    
    
    const parse_tx_events = (events:any) => {

        return  new Promise(async function (resolve, reject) {

            try{
                const starknet = starknetInstance;
                if(!starknet)
                {
                    console.log('Starknet instance is invalid')
                    reject({"error":"Starknet instance is invalid"})
                }else{
                    resolve(number.hexToDecimalString(events[0].data[2].toString()).toString())    
                }
            }catch(err){
                console.log(err)
                reject({"error":err})
            }
        })
    }

    const ERC721_nextTokenId = () => {

        return  new Promise(async function (resolve, reject) {

            try{
                const starknet = starknetInstance;
                if(!starknet)
                {
                    console.log('Starknet instance is invalid')
                    reject({"error":"Starknet instance is invalid"})
                }else{

                    let calldataArray: string[] = [];

                    const callObject: cairoContractData = {
                        contractAddress:contractAddress,
                        entrypoint:"next_token_id",
                        calldata: calldataArray
                    }

                    const rs = await starknet.provider.callContract(callObject)
                    .then((res:any)=>{
                        if(res.result)
                        {
                            resolve(number.hexToDecimalString(res.result[0].toString()))   

                        }else{
                            reject({"error":res.message})
                        }
                    })
                    .catch((err)=>{
                        reject({"error":err})
                    })
                }
            }catch(err){
                console.log(err)
                reject({"error":err})
            }
        })
    }

    const provider_get_transaction = (hash:string) => {

        return  new Promise(async function (resolve, reject) {

            try{
                const starknet = starknetInstance;
                if(!starknet)
                {
                    console.log('Starknet instance is invalid')
                    reject({"error":"Starknet instance is invalid"})
                }else{

                    const r = await starknet.provider.getTransactionReceipt(hash);
                    resolve(r) 
                }
            }catch(err){
                console.log(err)
                reject({"error":err})
            }
        })
    }


    



    // ************
    // utils
    // ************


    

    const getAspectUrl = async (tokenid:number) => {

        return (aspectBaseUrl + contractAddress + "/" + tokenid.toString());
    }

    const parseMetadata = async (url:string) => {

        const res = await fetch(url)
        const data = await res.json()

        // Pass data to the page via props
        return { data }
    }


    const shortStringToBigIntUtil = (originalString:string) => {
    
        if (originalString.length > SHORT_STRING_MAX_CHARACTERS) {
            const msg = `Short strings must have a max of ${SHORT_STRING_MAX_CHARACTERS} characters.`;
            return BigInt(0);
        }
    
        const invalidChars: { [key: string]: boolean } = {};
        const charArray : string[] = [];
        for (const c of originalString.split("")) {
            const charCode = c.charCodeAt(0);
            if (charCode > 127) {
                invalidChars[c] = true;
            }
            charArray.push(charCode.toString(16));
        }
    
        const invalidCharArray = Object.keys(invalidChars);
        if (invalidCharArray.length) {
            const msg = `Non-standard-ASCII character${
                invalidCharArray.length === 1 ? "" : "s"
            }: ${invalidCharArray.join(", ")}`;
        }
    
        return BigInt("0x" + charArray.join(""));
    }

    const convertStringToShortStringArray = (originalString:string) => {
        const result = originalString.match(/.{1,30}/g) || [];
        return result;
    }

    const getNearbyLandsByCoords = (x:number, y:number) => {

        var result = [];

        const range = 30;

        var coord_player_ranges = [
                [x
                ,y
                ],
                [x+range
                ,y+range
                ],
                [x+range
                ,y-range
                ],
                [x-range
                ,y+range
                ],
                [x-range
                ,y-range
                ] 
            ]


            mapData.forEach(node => {
                var foundInRange = intersects.boxCircle(node.minX, node.minY, node.w, node.h, x, y, range)
                if(foundInRange)
                {
                    result.push(node)
                }

            })
        return result;
    }

    const getLandInfoById = (id:number) => {

        var result = null;

        mapData.forEach(node => {

            if(node.id.toString() === id.toString()){
                result = node;
                return result;
            }
        })

        return result;
    }

    const getLandInfoByCoords = (x:number, y:number) => {

        var result = null;

        mapData.forEach(node => {
            if(checkCoordInRange(node,[x,y])){
                result = node;
                return result;
            }
        })

        return result;
    }

    function checkCoordInRange(node, coord){

        if(node.minX <=coord[0]
            && node.maxX >=coord[0]
            && node.minY <=coord[1]
            && node.maxY >=coord[1]
            ){
                return true
            }else{
                false
            }
    
    }

    function feltArrToStr(felts) {
        return felts.reduce(
            (memo, felt) => memo + Buffer.from(BigInt(felt).toString(16), "hex").toString(),
            ""
        );
    }

    // Convert a hex string to a byte array
function hexToBytes(hex) {
    for (var bytes = [], c = 0; c < hex.length; c += 2)
        bytes.push(parseInt(hex.substr(c, 2), 16));
    return bytes;
  }
  
  // Convert a byte array to a hex string
  function bytesToHex(bytes) {
    for (var hex = [], i = 0; i < bytes.length; i++) {
        var current = bytes[i] < 0 ? bytes[i] + 256 : bytes[i];
        hex.push((current >>> 4).toString(16));
        hex.push((current & 0xF).toString(16));
    }
    return hex.join("");
  }
  
  
  function hex_to_ascii(str1)
   {
      var hex  = str1.toString();
      var str = '';
      for (var n = 0; n < hex.length; n += 2) {
          str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));
      }
      return str;
   }
    

  // end of functions

    return (
        <StarknetContext.Provider
            value={{
                starknetAddress,
                starknetConnected,
                gamemode,
                buildtokenid,
                connectWallet,
                activateGameMode,
                getAspectUrl,
                shortStringToBigIntUtil,
                convertStringToShortStringArray,
                getLandInfoByCoords,
                getLandInfoById,
                getNearbyLandsByCoords,
                ERC721_ownerOf,
                ERC721_tokenURI,
                ERC721_updateTokenHash,
                ERC721_mint,
                ERC721_nextTokenId,
                setActiveLocationTokenId,
                provider_get_transaction,
                get_short_hash,
                parse_tx_events,
                get_svg_image,
                parseMetadata,
                pinJsonIPFS,
                fetchAssetAspect,
            }}
        >
            {children}
        </StarknetContext.Provider>
    );
};