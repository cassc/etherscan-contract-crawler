// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IS2Admin } from "./impl/IS2Admin.sol";
import { IS2Core } from "./impl/IS2Core.sol";
import { IS2Erc20 } from "./impl/IS2Erc20.sol";
import { IS2Getters } from "./impl/IS2Getters.sol";
import { IS2Storage } from "./impl/IS2Storage.sol";
import { MinHeap } from "./lib/MinHeap.sol";

/**
 * @title IkaniV2Staking
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
contract IkaniV2Staking is
    IS2Admin,
    IS2Getters
{
    //---------------- Constructor ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address ikani,
        address rewardsErc20
    )
        IS2Erc20(rewardsErc20)
        IS2Storage(ikani)
    {
        _disableInitializers();
    }

    //---------------- Initializer ----------------//

    function initialize(
        address admin
    )
        external
        initializer
    {
        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }
}