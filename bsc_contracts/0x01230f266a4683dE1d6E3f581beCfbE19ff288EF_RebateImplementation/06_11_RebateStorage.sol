// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/Admin.sol";

abstract contract RebateStorage is Admin {
    address public implementation;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, "Router: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    mapping(bytes32 => address) public brokerAddresses;

    mapping(address => bytes32) public brokerIds;

    mapping(address => BrokerInfo) public brokerInfos;

    mapping(bytes32 => address) public recruiterAddresses;

    mapping(address => bytes32) public recruiterIds;

    mapping(address => RecruiterInfo) public recruiterInfos;

    // trader => broker
    mapping(address => address) public traderReferral;

    // broker => recruiter
    mapping(address => address) public brokerReferral;

    // updater => isActive
    mapping(address => bool) public isUpdater;

    // approver => isActive, for recruiter approve
    mapping(address => bool) public isApprover;

    mapping(address => int256) public brokerFees;

    mapping(address => int256) public recruiterFees;

    mapping(address => uint256) public brokerClaimed;

    mapping(address => uint256) public recruiterClaimed;

    uint256 public updatedTimestamp;

    struct BrokerInfo {
        string code;
        bytes32 id;
        address referral;
    }

    struct RecruiterInfo {
        string code;
        bytes32 id;
    }
}