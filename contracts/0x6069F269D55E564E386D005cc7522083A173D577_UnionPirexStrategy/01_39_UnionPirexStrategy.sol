// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PirexBtrfly} from "src/PirexBtrfly.sol";
import {UnionPirexStaking} from "src/vault/UnionPirexStaking.sol";

contract UnionPirexStrategy is UnionPirexStaking {
    PirexBtrfly public immutable pirexBtrfly;

    error ZeroAddress();

    constructor(
        address _pirexBtrfly,
        address pxBTRFLY,
        address _distributor,
        address _vault
    ) UnionPirexStaking(pxBTRFLY, _distributor, _vault) {
        if (_pirexBtrfly == address(0)) revert ZeroAddress();

        pirexBtrfly = PirexBtrfly(_pirexBtrfly);
    }

    /**
        @notice Redeem pxBTRFLY rewards and transfer them to the distributor
        @param  epoch          uint256    Rewards epoch
        @param  rewardIndexes  uint256[]  Reward indexes
     */
    function redeemRewards(uint256 epoch, uint256[] calldata rewardIndexes)
        external
    {
        pirexBtrfly.redeemSnapshotRewards(epoch, rewardIndexes, distributor);
    }
}