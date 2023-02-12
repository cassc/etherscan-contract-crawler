// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "../lib/LibAsset.sol";

interface ITransferProxy {
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);

    function transfer(LibAsset.Asset calldata asset, address from, address to) external;
}