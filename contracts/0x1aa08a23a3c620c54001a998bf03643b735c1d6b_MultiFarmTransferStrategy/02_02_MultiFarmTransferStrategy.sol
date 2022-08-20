// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITransferStrategy} from "ITransferStrategy.sol";

contract MultiFarmTransferStrategy is ITransferStrategy {
    address public immutable multiFarm;

    constructor(address _multiFarm) {
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