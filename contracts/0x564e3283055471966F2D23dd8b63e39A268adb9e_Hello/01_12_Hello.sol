// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Hello is ERC721URIStorage, Ownable {

    uint test = 0;
    
    constructor(uint init) ERC721('Hello', 'HELLO'){
        test = init;
    }


}