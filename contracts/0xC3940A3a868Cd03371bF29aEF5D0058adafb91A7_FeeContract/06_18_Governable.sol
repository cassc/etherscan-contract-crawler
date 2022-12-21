// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/IGovernable.sol";

abstract contract Governable is IGovernable {
    address public override governor;
    address public override pendingGovernor;

    constructor(address _governor) {
        require(_governor != address(0), "Not valid address");
        governor = _governor;
    }

    function setPendingGovernor(address _pendingGovernor)
        external
        override
        onlyGovernor
    {
        require(_pendingGovernor != address(0), "Not valid address");
        pendingGovernor = _pendingGovernor;
        emit PendingGovernorSet(governor, pendingGovernor);
    }

    function acceptPendingGovernor() external override onlyPendingGovernor {
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit PendingGovernorAccepted(governor);
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Not Governor");
        _;
    }

    modifier onlyPendingGovernor() {
        require(msg.sender == pendingGovernor, "Not pendingGovernor");
        _;
    }
}