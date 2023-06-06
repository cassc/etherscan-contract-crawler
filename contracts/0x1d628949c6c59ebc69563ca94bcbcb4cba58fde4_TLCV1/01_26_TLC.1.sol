//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./components/ERC20VestableVotesUpgradeable.1.sol";
import "./interfaces/ITLC.1.sol";

/// @title TLC (v1)
/// @author Alluvial
/// @notice The TLC token has a max supply of 1,000,000,000 and 18 decimal places.
/// @notice Upon deployment, all minted tokens are send to account provided at construction, in charge of creating the vesting schedules
/// @notice The contract is based on ERC20Votes by OpenZeppelin. Users need to delegate their voting power to someone or themselves to be able to vote.
/// @notice The contract contains vesting logics allowing vested users to still be able to delegate their voting power while their tokens are held in an escrow
contract TLCV1 is ERC20VestableVotesUpgradeableV1, ITLCV1 {
    // Token information
    string internal constant NAME = "Liquid Collective";
    string internal constant SYMBOL = "TLC";

    // Initial supply of token minted
    uint256 internal constant INITIAL_SUPPLY = 1_000_000_000e18; // 1 billion TLC

    /// @notice Disables implementation initialization
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc ITLCV1
    function initTLCV1(address _account) external initializer {
        LibSanitize._notZeroAddress(_account);
        __ERC20Permit_init(NAME);
        __ERC20_init(NAME, SYMBOL);
        _mint(_account, INITIAL_SUPPLY);
    }

    /// @inheritdoc ITLCV1
    function migrateVestingSchedules() external reinitializer(2) {
        ERC20VestableVotesUpgradeableV1.migrateVestingSchedulesFromV1ToV2();
    }
}