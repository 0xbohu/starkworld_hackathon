import { useContext } from 'react';

import { StarknetContext } from "/src/@core/context/starknetContext";

export default function useStarknetLib() {
    return useContext(StarknetContext);
}