/**
 *Submitted for verification at Etherscan.io on 2023-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PairAddress {

    constructor() {
    }

    function getUniswapV2Pair(address token0) public pure returns (address){
        address token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        
        address pair = address(uint160(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        keccak256(abi.encodePacked(token0, token1)),
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        )))));

        return pair;
    }

}