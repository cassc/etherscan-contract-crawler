pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import { LinearVestingCore } from "./LinearVestingCore.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @notice Contract that will manage the linear dispersal of tokens to a single beneficiary
contract SingleScheduleLinearVesting is LinearVestingCore, UUPSUpgradeable {

    struct Schedule {
        uint256 start;
        uint256 end;
        uint256 cliff;
        uint256 amount;
        address beneficiary;
    }

    /// @notice Schedule metadata
    Schedule public vestingSchedule;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(
        address _vestedToken,
        address _contractOwner,
        Schedule calldata _vestingSchedule
    ) external initializer {
        vestingSchedule = _vestingSchedule;
        vestingVersion += 1;

        __LinearVestingCore_init(_vestedToken, _contractOwner);
        __UUPSUpgradeable_init();
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @notice Beneficiary can call this method to claim tokens owed up to the current block
    function claim() external whenNotPaused {
        require(vestingVersion != 0, "Contract under maintenance");

        uint256 amountToSend = _drawDown(
            vestingSchedule.start,
            vestingSchedule.end,
            vestingSchedule.cliff,
            vestingSchedule.amount,
            vestingSchedule.beneficiary
        );

        require(
            vestedToken.transfer(vestingSchedule.beneficiary, amountToSend),
            "Failed"
        );
    }
}