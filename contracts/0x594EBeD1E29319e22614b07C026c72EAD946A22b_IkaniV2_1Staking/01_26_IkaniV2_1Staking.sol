// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IS2_1Admin } from "./impl/IS2_1Admin.sol";
import { IS2Core } from "../v2/impl/IS2Core.sol";
import { IS2_1Erc20 } from "./impl/IS2_1Erc20.sol";
import { IS2Getters } from "../v2/impl/IS2Getters.sol";
import { IS2Storage } from "../v2/impl/IS2Storage.sol";
import { MinHeap } from "../v2/lib/MinHeap.sol";

/**
 * @title IkaniV2_1Staking
 * @author Cyborg Labs, LLC
 *
 * @dev Implements ERC-721 in-place staking with rewards.
 *
 *  Rewards are earned at a configurable base rate per staked NFT, with four bonus multipliers:
 *
 *    - Account-level (i.e. owner-level) bonuses:
 *      - Number of unique staked fabric traits
 *      - Number of unique staked season traits
 *
 *    - Token-level bonuses:
 *      - Foil trait
 *      - Staked duration checkpoints
 */
contract IkaniV2_1Staking is
    IS2_1Admin,
    IS2Getters
{
    //---------------- Constructor ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address ikani,
        address rewardsErc20
    )
        IS2_1Erc20(rewardsErc20)
        IS2Storage(ikani)
    {
        _disableInitializers();
    }
}