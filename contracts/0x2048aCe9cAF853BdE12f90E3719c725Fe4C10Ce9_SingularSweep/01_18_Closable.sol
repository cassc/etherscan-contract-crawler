// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable2Step} from "./openzeppelin/Ownable2Step.sol";

/// @notice Guardian can stop buys through contarct
abstract contract Closable is Ownable2Step {
    address public guardian;
    bool public openForTrades;

    event GuardianChanged(
        address indexed previousGuardian,
        address indexed newGuardian
    );

    event Opened();
    event Closed();

    error ClosedForTrades();
    error NotGuardian();

    modifier isOpenForTrades() {
        if (!openForTrades) revert ClosedForTrades();
        _;
    }

    constructor(address _guardian) {
        guardian = _guardian;
        openForTrades = true;
    }

    function changeGuardian(address newGuardian) external onlyOwner {
        address oldGuardian = guardian;
        guardian = newGuardian;

        emit GuardianChanged(oldGuardian, guardian);
    }

    function setOpenForTrades(bool _openForTrades) external onlyOwner {
        openForTrades = _openForTrades;

        if (openForTrades) emit Opened();
        else emit Closed();
    }

    function close() external {
        if (_msgSender() != guardian) revert NotGuardian();

        openForTrades = false;

        emit Closed();
    }
}