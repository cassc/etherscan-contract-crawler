// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libs/StoreNFT.sol";

contract ChainZokuStoredNftPartners is StoreNFT {

    constructor(address _signAddress){
        Signature.setSignAddress(_signAddress);
        Signature.setHashSign(4854518);
    }
}