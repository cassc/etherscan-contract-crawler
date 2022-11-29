// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITransferController} from "ITransferController.sol";
import {Initializable} from "Initializable.sol";

contract OpenTransferController is ITransferController, Initializable {
    function initialize() external initializer {}

    function canTransfer(
        address,
        address,
        uint256
    ) public pure returns (bool) {
        return true;
    }
}