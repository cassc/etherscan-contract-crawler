// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { LS1Admin } from "./impl/LS1Admin.sol";
import { LS1Borrowing } from "./impl/LS1Borrowing.sol";
import { LS1DebtAccounting } from "./impl/LS1DebtAccounting.sol";
import { LS1ERC20 } from "./impl/LS1ERC20.sol";
// import { LS1Failsafe } from "./impl/LS1Failsafe.sol";
import { LS1Getters } from './impl/LS1Getters.sol';
import { LS1Operators } from "./impl/LS1Operators.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title LiquidityStakingV1
 * @author MarginX
 *
 * @notice Contract for staking tokens, which may then be borrowed by pre-approved borrowers.
 *
 *  NOTE: Most functions will revert if epoch zero has not started.
 */
contract LiquidityStakingV1 is
    Initializable,
    LS1Borrowing,
    LS1DebtAccounting,
    LS1Admin,
    LS1Operators,
    LS1Getters,
    // LS1Failsafe,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ============ External Functions ============

    function initialize(
        IERC20Upgradeable stakedToken,
        IERC20Upgradeable rewardsToken,
        address rewardsTreasury,
        uint256 distributionStart,
        uint256 distributionEnd,
        uint256 interval,
        uint256 offset,
        uint256 blackoutWindow
    ) external initializer {
        require(distributionEnd >= distributionStart, "Invalid");
        STAKED_TOKEN = stakedToken;
        REWARDS_TOKEN = rewardsToken;
        REWARDS_TREASURY = rewardsTreasury;
        DISTRIBUTION_START = distributionStart;
        DISTRIBUTION_END = distributionEnd;
        __LS1Roles_init();
        __LS1EpochSchedule_init(interval, offset, blackoutWindow);
        __LS1Rewards_init();
        __LS1BorrowerAllocations_init();
        __UUPSUpgradeable_init();
    }

    // ============ Internal Functions ============

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(OWNER_ROLE)
    {}
}