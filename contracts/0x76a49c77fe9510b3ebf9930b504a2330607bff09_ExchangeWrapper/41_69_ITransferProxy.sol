// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../librairies/LibAsset.sol";

interface ITransferProxy {
    function transfer(LibAsset.Asset calldata asset, address from, address to) external;
}