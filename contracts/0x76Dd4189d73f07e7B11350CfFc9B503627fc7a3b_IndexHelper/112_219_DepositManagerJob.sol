// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./interfaces/external/IKeep3r.sol";

import "./DepositManager.sol";

contract DepositManagerJob is DepositManager {
    /// @notice Address of Keeper Network V2
    address public immutable keep3r;

    constructor(
        address _keep3r,
        address _registry,
        uint16 _maxLossInBP,
        uint32 _depositInterval
    ) DepositManager(_registry, _maxLossInBP, _depositInterval) {
        keep3r = _keep3r;
    }

    /// @inheritdoc IDepositManager
    function updateDeposits() public override {
        require(IKeep3r(keep3r).isKeeper(msg.sender), "DepositManager: !KEEP3R");

        super.updateDeposits();

        IKeep3r(keep3r).worked(msg.sender);
    }
}