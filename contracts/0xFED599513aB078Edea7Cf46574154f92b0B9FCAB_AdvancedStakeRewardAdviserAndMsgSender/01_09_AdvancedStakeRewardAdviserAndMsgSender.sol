// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import "./actions/AdvancedStakingBridgedDataCoder.sol";
import "./actions/Constants.sol";
import "./interfaces/IActionMsgReceiver.sol";
import "./interfaces/IFxStateSender.sol";
import "./StakeZeroRewardAdviser.sol";

/***
 * @title AdvancedStakeRewardAdviserAndMsgSender
 * @notice The "zero reward adviser" for the `RewardMaster` that sends `STAKE` action messages over
 * the PoS bridge to the STAKE_MSG_RECEIVER.
 * @dev It is assumed to run on the mainnet/Goerli and be authorized with the `RewardMaster` on the
 * same network as the "Reward Adviser" for "advanced" stakes.
 * As the "Reward Adviser" it gets called `getRewardAdvice` by the `RewardMaster` every time a user
 * creates or withdraws an "advanced" stake. It returns the "zero" advices, i.e. the `Advice` data
 * structure with zero `sharesToCreate` and `sharesToRedeem`.
 * On "zero" advices, the RewardMaster skips creating/redeeming "treasure shares" for/to stakers.
 * If the `getRewardAdvice` is called w/ the action STAKE (i.e. a new stake is being created), this
 * contract sends the STAKE message over the "Fx-Portal" (the PoS bridge run by the Polygon team)
 * to the STAKE_MSG_RECEIVER on the Polygon/Mumbai. The STAKE_MSG_RECEIVER is supposed to be the
 * `AdvancedStakeActionMsgRelayer` contract that processes the bridged messages, rewarding stakers
 * on the Polygon/Mumbai.
 */
contract AdvancedStakeRewardAdviserAndMsgSender is
    StakeZeroRewardAdviser,
    AdvancedStakingBridgedDataCoder
{
    event StakeMsgBridged(uint256 _nonce, bytes data);

    // solhint-disable var-name-mixedcase

    /// @notice Address of the `FxRoot` contract on the mainnet/Goerli network
    /// @dev `FxRoot` is the contract of the "Fx-Portal" on the mainnet/Goerli.
    address public immutable FX_ROOT;

    /// @notice Address of the RewardMaster contract on the mainnet/Goerli
    address public immutable REWARD_MASTER;

    /// @notice Address on the AdvancedStakeActionMsgRelayer on the Polygon/Mumbai
    address public immutable ACTION_MSG_RECEIVER;

    // solhint-enable var-name-mixedcase

    /// @notice Message nonce (i.e. sequential number of the latest message)
    uint256 public nonce;

    /// @param _rewardMaster Address of the RewardMaster contract on the mainnet/Goerli
    /// @param _actionMsgReceiver Address of the AdvancedStakeActionMsgRelayer on Polygon/Mumbai
    /// @param _fxRoot Address of the `FxRoot` (PoS Bridge) contract on mainnet/Goerli
    constructor(
        // slither-disable-next-line similar-names
        address _rewardMaster,
        address _actionMsgReceiver,
        address _fxRoot
    ) StakeZeroRewardAdviser(ADVANCED_STAKE, ADVANCED_UNSTAKE) {
        require(
            _fxRoot != address(0) &&
                _actionMsgReceiver != address(0) &&
                _rewardMaster != address(0),
            "AMS:E01"
        );

        FX_ROOT = _fxRoot;
        REWARD_MASTER = _rewardMaster;
        ACTION_MSG_RECEIVER = _actionMsgReceiver;
    }

    // It is called withing the `function getRewardAdvice`
    function _onRequest(bytes4 action, bytes memory message) internal override {
        // Ignore other messages except the STAKE
        if (action != STAKE) return;

        // Overflow ignored as the nonce is unexpected ever be that big
        uint24 _nonce = uint24(nonce + 1);
        nonce = uint256(_nonce);

        bytes memory content = _encodeBridgedData(_nonce, action, message);
        // known contract call - no need in reentrancy guard
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        IFxStateSender(FX_ROOT).sendMessageToChild(
            ACTION_MSG_RECEIVER,
            content
        );

        emit StakeMsgBridged(_nonce, content);
    }
}