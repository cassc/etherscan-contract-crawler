// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Common} from "../libraries/Common.sol";

interface IRewardDistributor {
    /**
        @notice Update rewards metadata
        @param  distributions  Distribution[] List of reward distribution details
     */
    function updateRewardsMetadata(
        Common.Distribution[] calldata distributions
    ) external;

    /** 
        @notice Set the contract's pause state (ie. before taking snapshot for the harvester)
        @param  state  bool  Pause state
    */
    function setPauseState(bool state) external;

    /**
        @notice Claim rewards based on the specified metadata
        @param  _claims  Claim[] List of claim metadata
     */
    function claim(Common.Claim[] calldata _claims) external;
}