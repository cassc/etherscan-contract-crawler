// SPDX-License-Identifier: GPL-1.0-or-later
pragma solidity ^0.8.9;

import "../Interfaces/IERC20.sol";

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 guaranteedAmount;
    uint256 flags;
    address referrer;
    bytes permit;
}

struct MinimifiedSubscriptionManagerStruct {
    uint256 id;
    string name;
    string tokenSymbol;
    uint256 activeSubscriptionCount;
}

struct SubscriptionManagerStruct {
    uint256 id;
    string name;
    address tokenAddress;
    string tokenSymbol;
    uint256 tokenDecimals;
    uint256 activeSubscriptionCount;
    address treasury;
    SubscriptionStruct[] subscriptions;
    address[] owners;
}

struct SubscriptionStruct {
    uint256 price;
    bool isActive;
    string name;
}

struct UserData {
    uint256 subscriptionEndDate;
    uint256 subscriptionId;
    uint256 approval;
    uint256 lastPayment;
    bool canceled;
}

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable; // 0x4b64e492
}

interface IOpenOceanCaller {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }

    function makeCall(CallDescription memory desc) external;

    function makeCalls(CallDescription[] memory desc) external payable;
}

interface IRouter {
    function swap(
        IOpenOceanCaller caller,
        SwapDescription calldata desc,
        IOpenOceanCaller.CallDescription[] calldata calls
    ) external payable returns (uint returnAmount);
}