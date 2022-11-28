// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskSubscriptionManager {

    enum CheckType {
        None,
        Active,
        PastDue
    }

    function queueItem(CheckType _checkType, uint32 _bucket, uint256 _idx) external view returns(uint256);

    function queueSize(CheckType _checkType, uint32 _bucket) external view returns(uint256);

    function queuePosition(CheckType _checkType) external view returns(uint32);

    function processSinglePayment(address _consumer, address _provider,
        uint256 _subscriptionId, uint256 _value) external returns(bool);

    function renewSubscription(uint256 _subscriptionId) external;

    /** @dev Emitted when the keeper job performs renewals. */
    event SubscriptionManagerReport(uint256 limit, uint256 renewals, uint256 depth, CheckType checkType,
        uint256 queueRemaining, uint32 currentBucket);

    /** @dev Emitted when manager parameters are changed. */
    event SetParameters();
}