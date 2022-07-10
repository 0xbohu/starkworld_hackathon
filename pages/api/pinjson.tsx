// Next.js API route support: https://nextjs.org/docs/api-routes/introduction
require('dotenv').config();
import type { NextApiRequest, NextApiResponse } from 'next/types'

import axios from 'axios';

const uuidv1 = require("uuidv1");

const multiparty = require("multiparty");

const PINATA_JWT = process.env.PINATA_JWT; 
const PINATA_GATEWAY = process.env.PINATA_GATEWAY; 

export default async function handler(req: NextApiRequest, res: NextApiResponse) {

    try{
        if(req.body)
        {
            const filename = uuidv1();

            var data = JSON.stringify({
                "pinataOptions": {
                "cidVersion": 1
                },
                "pinataMetadata": {
                "name": "w-" + filename,
                },
                "pinataContent": req.body
            });
            
            var config = {
            method: 'post',
            url: 'https://api.pinata.cloud/pinning/pinJSONToIPFS',
            headers: { 
                'Content-Type': 'application/json', 
                'Authorization': 'Bearer ' + PINATA_JWT
            },
            data : data
            };
            
            const ipfsres = await axios(config)
            .then(function(response){
                res.status(200).json({ data: response.data })
            })
            .catch(function (error) {
                res.status(500).json({ error: error.data })
            })
        }else{
            res.status(500).json({ error: "unknown error" })
        }
    }catch(err){
        res.status(500).json({ error: err })
    }
  
}