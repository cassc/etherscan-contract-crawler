// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

import {WithdrawInfo, ExitValidatorInfo} from "src/library/ConsensusStruct.sol";
/**
 * @title Interface for IVaultManager
 * @notice Vault will manage methods for rewards, commissions, tax
 */

interface IVaultManager {
    /**
     * @notice Settlement and reinvestment execution layer rewards
     * @param _operatorIds operator id
     */
    function settleAndReinvestElReward(uint256[] memory _operatorIds) external;

    /**
     * @notice Receive the oracle machine consensus layer information, initiate re-investment consensus layer rewards, trigger and update the exited nft
     * @param _withdrawInfo withdraw info
     * @param _exitValidatorInfo exit validator info
     * @param _nftExitDelayedTokenIds nft with delayed exit
     * @param _largeExitDelayedRequestIds large Requests for Delayed Exit
     * @param _thisTotalWithdrawAmount The total settlement amount reported this time
     */
    function reportConsensusData(
        WithdrawInfo[] memory _withdrawInfo,
        ExitValidatorInfo[] memory _exitValidatorInfo,
        uint256[] memory _nftExitDelayedTokenIds, // user nft
        uint256[] memory _largeExitDelayedRequestIds, // large unstake request id
        uint256 _thisTotalWithdrawAmount
    ) external;
}