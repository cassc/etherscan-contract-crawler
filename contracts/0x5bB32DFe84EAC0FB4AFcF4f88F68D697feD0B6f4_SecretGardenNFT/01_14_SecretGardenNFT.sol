//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./AirdropNFT.sol";

contract SecretGardenNFT is AirdropNFT {

    constructor(address royaltyContract_, string memory customBaseURI_)
        AirdropNFT(royaltyContract_, customBaseURI_, "Secret Garden NFT", "504-SG")
    {
    }
}