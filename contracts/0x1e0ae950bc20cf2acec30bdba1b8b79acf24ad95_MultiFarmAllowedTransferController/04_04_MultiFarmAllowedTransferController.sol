// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITransferController} from "ITransferController.sol";
import {Initializable} from "Initializable.sol";

contract MultiFarmAllowedTransferController is ITransferController, Initializable {
    address public multiFarm;

    function initialize(address _multiFarm) external initializer {
        multiFarm = _multiFarm;
    }

    function canTransfer(
        address from,
        address to,
        uint256
    ) public view returns (bool) {
        return to == multiFarm || from == multiFarm;
    }
}