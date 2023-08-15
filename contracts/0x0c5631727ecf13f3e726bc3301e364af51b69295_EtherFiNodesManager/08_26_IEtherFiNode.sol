// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IEtherFiNodesManager.sol";

interface IEtherFiNode {
    // State Transition Diagram for StateMachine contract:
    //
    //      NOT_INITIALIZED
    //              |
    //              ↓
    //      STAKE_DEPOSITED
    //           /      \
    //          /        \
    //         ↓          ↓
    //         LIVE    CANCELLED
    //         |  \ \ 
    //         |   \ \
    //         |   ↓  --> EVICTED
    //         |  BEING_SLASHED
    //         |    /
    //         |   /
    //         ↓  ↓
    //         EXITED
    //           |
    //           ↓
    //      FULLY_WITHDRAWN
    // Transitions are only allowed as directed above.
    // For instance, a transition from STAKE_DEPOSITED to either LIVE or CANCELLED is allowed,
    // but a transition from STAKE_DEPOSITED to NOT_INITIALIZED, BEING_SLASHED, or EXITED is not.
    //
    // All phase transitions should be made through the setPhase function,
    // which validates transitions based on these rules.
    enum VALIDATOR_PHASE {
        NOT_INITIALIZED,
        STAKE_DEPOSITED,
        LIVE,
        EXITED,
        FULLY_WITHDRAWN,
        CANCELLED,
        BEING_SLASHED,
        EVICTED
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

    function calculatePayouts(
        uint256 _totalAmount,
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    ) external view returns (uint256, uint256, uint256, uint256);

    function getStakingRewardsPayouts(
        uint256 _beaconBalance,
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    ) external view returns (uint256, uint256, uint256, uint256);

    function getProtocolRewardsPayouts(
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    ) external view returns (uint256, uint256, uint256, uint256);

    function getNonExitPenalty(
        uint32 _tNftExitRequestTimestamp, 
        uint32 _bNftExitRequestTimestamp
    ) external view returns (uint256);

    function getRewardsPayouts(
        uint256 _beaconBalance,
        bool _stakingRewards,
        bool _protocolRewards,
        bool _vestedAuctionFee,
        bool _assumeFullyVested,
        IEtherFiNodesManager.RewardsSplit memory _SRsplits,
        IEtherFiNodesManager.RewardsSplit memory _PRsplits,
        uint256 _scale
    ) external view returns (uint256, uint256, uint256, uint256);

    function calculateTVL(
        uint256 _beaconBalance,
        bool _stakingRewards,
        bool _protocolRewards,
        bool _vestedAuctionFee,
        bool _assumeFullyVested,
        IEtherFiNodesManager.RewardsSplit memory _SRsplits,
        IEtherFiNodesManager.RewardsSplit memory _PRsplits,
        uint256 _scale
    ) external view returns (uint256, uint256, uint256, uint256);

    // Non-VIEW functions
    function setPhase(VALIDATOR_PHASE _phase) external;

    function setIpfsHashForEncryptedValidatorKey(
        string calldata _ipfs
    ) external;

    function setLocalRevenueIndex(uint256 _localRevenueIndex) external payable;

    function setExitRequestTimestamp() external;

    function markExited(uint32 _exitTimestamp) external;

    function markEvicted() external;

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