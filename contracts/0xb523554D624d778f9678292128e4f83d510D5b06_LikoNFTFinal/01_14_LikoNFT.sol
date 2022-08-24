// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./AvatarNFT.sol";

contract LikoNFTFinal is AvatarNFT {

    constructor() AvatarNFT(0.1 ether, 800, 100, "ipfs://QmYbt8gfS6UVFMkqLieJcu2gvFXwjuetALCfNYK89Mn8AG/", "LIKOMERCH", "LIKOMERCH") {}
}