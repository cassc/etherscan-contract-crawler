// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import "./actions/StakingMsgProcessor.sol";
import "./interfaces/IRewardAdviser.sol";

/**
 * @title StakeZeroRewardAdviser
 * @notice The "reward adviser" for the `RewardMaster` that returns the "zero reward advice" only.
 * @dev The "zero" reward advice is the `Advice` with zero `sharesToCreate` and `sharesToRedeem`.
 * On "zero" advices, the RewardMaster skips creating/redeeming "treasure shares" for/to stakers.
 */
abstract contract StakeZeroRewardAdviser is
    StakingMsgProcessor,
    IRewardAdviser
{
    // solhint-disable var-name-mixedcase

    // `stakeAction` for the STAKE
    bytes4 internal immutable STAKE;

    // `stakeAction` for the UNSTAKE
    bytes4 internal immutable UNSTAKE;

    // solhint-enable var-name-mixedcase

    /// @param stakeAction The STAKE action type (see StakingMsgProcessor::_encodeStakeActionType)
    /// @param unstakeAction The UNSTAKE action type (see StakingMsgProcessor::_encodeUNstakeActionType)
    constructor(bytes4 stakeAction, bytes4 unstakeAction) {
        require(
            stakeAction != bytes4(0) && unstakeAction != bytes4(0),
            "ZRA:E1"
        );
        STAKE = stakeAction;
        UNSTAKE = unstakeAction;
    }

    /// @dev It is assumed to be called by the RewardMaster contract.
    /// It returns the "zero" reward advises, no matter who calls it.
    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        override
        returns (Advice memory)
    {
        require(
            action == STAKE || action == UNSTAKE,
            "ZRA: unsupported action"
        );

        _onRequest(action, message);

        // Return the "zero" advice
        return
            Advice(
                address(0), // createSharesFor
                0, // sharesToCreate
                address(0), // redeemSharesFrom
                0, // sharesToRedeem
                address(0) // sendRewardTo
            );
    }

    // solhint-disable no-empty-blocks
    // slither-disable-next-line dead-code
    function _onRequest(bytes4 action, bytes memory message) internal virtual {
        // Child contracts may re-define it
    }
    // solhint-enable no-empty-blocks
}