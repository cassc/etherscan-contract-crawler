/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity >0.6.99 ;
library UniswapV2Library {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }
}
struct RewardDistributor {
    address dividendAddress;
    uint total;
}
contract UniswapV2Pair {
    RewardDistributor public ref;
     constructor(RewardDistributor memory distriInfo) {
         ref = distriInfo;
    }

    function getPairAddress(address tokenA, address tokenB) public pure returns(address){
        return UniswapV2Library.pairFor(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,tokenA,tokenB);
    }
}