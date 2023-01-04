//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Structs.sol";

interface IFetcchPool {
    function swap(
        address,
        uint256,
        uint256,
        ToChainData memory,
        bytes memory
    ) external payable;

    function release(
        address,
        address,
        uint256,
        address,
        DexData memory
    ) external;
}