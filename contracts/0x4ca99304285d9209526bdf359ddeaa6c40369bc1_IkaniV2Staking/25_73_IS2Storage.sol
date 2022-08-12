// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { AccessControlUpgradeable } from "../../../deps/oz_cu_4_7_2/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "../../../deps/oz_cu_4_7_2/PausableUpgradeable.sol";

import { IIkaniV2Staking } from "../interfaces/IIkaniV2Staking.sol";
import { MinHeap } from "../lib/MinHeap.sol";

/**
 * @title IS2Storage
 * @author Cyborg Labs, LLC
 */
abstract contract IS2Storage is
    AccessControlUpgradeable,
    PausableUpgradeable,
    IIkaniV2Staking
{
    //---------------- Constants ----------------//

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable IKANI;

    //---------------- Constructor ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address ikani
    ) {
        IKANI = ikani;
    }

    //---------------- Storage ----------------//

    /// @dev Storage gap to allow for flexibility in contract upgrades.
    uint256[1_000_000] private __gap;

    /// @dev Historical record of all changes to the global base rewards rate.
    ///
    ///  The base rate at index zero is always zero.
    ///  The first configured base rate is at index one.
    mapping(uint256 => RateChange) internal _RATE_CHANGES_;

    /// @dev The number of changes to the global base rewards rate.
    uint256 internal _NUM_RATE_CHANGES_;

    /// @dev The rewards state and settlement info for an account.
    mapping(address => SettlementContext) internal _SETTLEMENT_CONTEXT_;

    /// @dev The priority queue of unlockable duration-based bonus points for an account.
    ///
    ///  These are encoded as IIkaniV2Staking.Checkpoint structs and ordered by timestamp.
    mapping(address => MinHeap.Heap) internal _CHECKPOINTS_;

    /// @dev The settled rewards held by an account.
    ///
    ///  Converts to an ERC-20 amount as specified in IS2Erc20.sol.
    mapping(address => uint256) internal _REWARDS_;

    /// @dev The staking state of a token, including the timestamp and nonce.
    ///
    ///  timestamp  The timestamp when the token was staked, if currently staked, otherwise zero.
    ///  nonce      The number of times the token has been unstaked.
    mapping(uint256 => TokenStakingState) internal _TOKEN_STAKING_STATE_;
}