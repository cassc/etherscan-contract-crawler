// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IEtherFiNodesManager.sol";

interface IEtherFiNode {
    //The state of the validator
    enum VALIDATOR_PHASE {
        NOT_INITIALIZED,
        STAKE_DEPOSITED,
        LIVE,
        EXITED,
        FULLY_WITHDRAWN,
        CANCELLED,
        BEING_SLASHED
    }

    // VIEW functions
    function phase() external view returns (VALIDATOR_PHASE);

    function ipfsHashForEncryptedValidatorKey()
        external
        view
        returns (string memory);

    function localRevenueIndex() external view returns (uint256);

    function stakingStartTimestamp() external view returns (uint32);

    function exitRequestTimestamp() external view returns (uint32);

    function exitTimestamp() external view returns (uint32);

    function vestedAuctionRewards() external view returns (uint256);

    function getNonExitPenalty(
        uint128 _principal,
        uint64 _dailyPenalty,
        uint32 _endTimestamp
    ) external view returns (uint256);

    function calculatePayouts(
        uint256 _totalAmount,
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    ) external view returns (uint256, uint256, uint256, uint256);

    function getStakingRewardsPayouts(
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    ) external view returns (uint256, uint256, uint256, uint256);

    function getProtocolRewardsPayouts(
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    ) external view returns (uint256, uint256, uint256, uint256);

    function getRewardsPayouts(
        bool _stakingRewards,
        bool _protocolRewards,
        bool _vestedAuctionFee,
        IEtherFiNodesManager.RewardsSplit memory _SRsplits,
        uint256 _SRscale,
        IEtherFiNodesManager.RewardsSplit memory _PRsplits,
        uint256 _PRscale
    ) external view returns (uint256, uint256, uint256, uint256);

    function getFullWithdrawalPayouts(
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale,
        uint128 _principal,
        uint64 _dailyPenalty
    ) external view returns (uint256, uint256, uint256, uint256);

    // Non-VIEW functions
    function setPhase(VALIDATOR_PHASE _phase) external;

    function setIpfsHashForEncryptedValidatorKey(
        string calldata _ipfs
    ) external;

    function setLocalRevenueIndex(uint256 _localRevenueIndex) external payable;

    function setExitRequestTimestamp() external;

    function markExited(uint32 _exitTimestamp) external;

    function markBeingSlahsed() external;

    function markFullyWithdrawn() external;

    function receiveVestedRewardsForStakers() external payable;

    function processVestedAuctionFeeWithdrawal() external;

    // Withdraw Rewards
    function moveRewardsToManager(uint256 _amount) external;

    function withdrawFunds(
        address _treasury,
        uint256 _treasuryAmount,
        address _operator,
        uint256 _operatorAmount,
        address _tnftHolder,
        uint256 _tnftAmount,
        address _bnftHolder,
        uint256 _bnftAmount
    ) external;
}