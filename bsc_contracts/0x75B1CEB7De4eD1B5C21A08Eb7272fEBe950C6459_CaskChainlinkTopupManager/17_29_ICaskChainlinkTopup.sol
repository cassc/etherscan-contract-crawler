// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskChainlinkTopup {

    enum ChainlinkTopupStatus {
        None,
        Active,
        Paused,
        Canceled
    }

    enum ManagerCommand {
        None,
        Cancel,
        Pause
    }

    enum SkipReason {
        None,
        PaymentFailed,
        SwapFailed
    }

    enum TopupType {
        None,
        Automation,
        VRF,
        Direct
    }

    struct ChainlinkTopup {
        address user;
        uint256 groupId;
        uint256 lowBalance;
        uint256 topupAmount;
        uint256 currentAmount;
        uint256 currentBuyQty;
        uint256 numTopups;
        uint256 numSkips;
        uint32 createdAt;
        uint256 targetId;
        address registry;
        TopupType topupType;
        ChainlinkTopupStatus status;
        uint32 retryAfter;
    }

    struct ChainlinkTopupGroup {
        bytes32[] chainlinkTopups;
    }

    function createChainlinkTopup(
        uint256 _lowBalance,
        uint256 _topupAmount,
        uint256 _targetId,
        address _registry,
        TopupType _topupType
    ) external returns(bytes32);

    function getChainlinkTopup(bytes32 _chainlinkTopupId) external view returns (ChainlinkTopup memory);

    function getChainlinkTopupGroup(uint256 _chainlinkTopupGroupId) external view returns (ChainlinkTopupGroup memory);

    function getUserChainlinkTopup(address _user, uint256 _idx) external view returns (bytes32);

    function getUserChainlinkTopupCount(address _user) external view returns (uint256);

    function cancelChainlinkTopup(bytes32 _chainlinkTopupId) external;

    function pauseChainlinkTopup(bytes32 _chainlinkTopupId) external;

    function resumeChainlinkTopup(bytes32 _chainlinkTopupId) external;

    function managerCommand(bytes32 _chainlinkTopupId, ManagerCommand _command) external;

    function managerProcessed(bytes32 _chainlinkTopupId, uint256 _amount, uint256 _buyQty, uint256 _fee) external;

    function managerSkipped(bytes32 _chainlinkTopupId, uint32 _retryAfter, SkipReason _skipReason) external;

    event ChainlinkTopupCreated(bytes32 indexed chainlinkTopupId, address indexed user, uint256 lowBalance,
        uint256 topupAmount, uint256 targetId, address registry, TopupType topupType);

    event ChainlinkTopupPaused(bytes32 indexed chainlinkTopupId, address indexed user, uint256 targetId,
        address registry, TopupType topupType);

    event ChainlinkTopupResumed(bytes32 indexed chainlinkTopupId, address indexed user, uint256 targetId,
        address registry, TopupType topupType);

    event ChainlinkTopupSkipped(bytes32 indexed chainlinkTopupId, address indexed user, uint256 targetId,
        address registry, TopupType topupType, SkipReason skipReason);

    event ChainlinkTopupProcessed(bytes32 indexed chainlinkTopupId, address indexed user, uint256 targetId,
        address registry, TopupType topupType, uint256 amount, uint256 buyQty, uint256 fee);

    event ChainlinkTopupCanceled(bytes32 indexed chainlinkTopupId, address indexed user, uint256 targetId,
        address registry, TopupType topupType);
}