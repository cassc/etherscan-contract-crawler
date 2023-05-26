// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./Keep3rJob.sol";
import "./OnlyEOA.sol";
import "../interfaces/IKeep3rBondedJob.sol";

abstract contract Keep3rBondedJob is IKeep3rBondedJob, Keep3rJob, OnlyEOA {
    /// @inheritdoc IKeep3rBondedJob
    address public requiredBond;
    /// @inheritdoc IKeep3rBondedJob
    uint256 public requiredMinBond;
    /// @inheritdoc IKeep3rBondedJob
    uint256 public requiredEarnings;
    /// @inheritdoc IKeep3rBondedJob
    uint256 public requiredAge;

    // Methods

    /// @inheritdoc IKeep3rBondedJob
    function setKeep3rRequirements(
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age
    ) public onlyGovernor {
        _setKeep3rRequirements(_bond, _minBond, _earned, _age);
    }

    // Internals

    function _setKeep3rRequirements(
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age
    ) internal {
        requiredBond = _bond;
        requiredMinBond = _minBond;
        requiredEarnings = _earned;
        requiredAge = _age;
        emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age);
    }

    function _isValidKeeper(address _keeper) internal virtual override {
        if (onlyEOA) _validateEOA(_keeper);
        if (
            !IKeep3rV2(keep3r).isBondedKeeper(
                _keeper,
                requiredBond,
                requiredMinBond,
                requiredEarnings,
                requiredAge
            )
        ) revert KeeperNotValid();
    }
}