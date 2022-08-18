//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

interface ILSSVMPair {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function withdrawAllETH() external;
}