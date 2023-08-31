// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AssetType, OrderType, Transfer } from "../lib/Structs.sol";

interface IDelegate {
    function transfer(
        address caller,
        OrderType orderType,
        Transfer[] calldata transfers,
        uint256 length
    ) external returns (bool[] memory successful);
}