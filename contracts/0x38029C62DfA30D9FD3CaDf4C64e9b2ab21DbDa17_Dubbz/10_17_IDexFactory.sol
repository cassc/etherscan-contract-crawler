// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.17;

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}