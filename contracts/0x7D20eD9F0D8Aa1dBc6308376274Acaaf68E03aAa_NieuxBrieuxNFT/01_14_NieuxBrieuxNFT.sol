//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./AirdropNFT.sol";

contract NieuxBrieuxNFT is AirdropNFT {

    constructor(address royaltyContract_, string memory customBaseURI_)
        AirdropNFT(royaltyContract_, customBaseURI_, "Nieux Brieux NFT", "504-NB")
    {
    }
}