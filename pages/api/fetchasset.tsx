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
            

            var contract = req.body.contract;
            var tokenid = req.body.tokenid;

            var config = {
                method: 'get',
                url: 'https://api-testnet.aspect.co/api/v0/asset/' + contract + "/" + tokenid,
                headers: { 
                    'Content-Type': 'application/json'
                }
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