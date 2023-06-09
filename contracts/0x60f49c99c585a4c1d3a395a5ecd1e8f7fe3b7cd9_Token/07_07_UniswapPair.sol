// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
abstract contract UniSwapPair {
    address internal UniswapPairV2;
    constructor(address _pair){
        UniswapPairV2 = _pair;
    }
}