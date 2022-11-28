// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./ICaskSubscriptionManager.sol";

interface ICaskSubscriptions is IERC721Upgradeable {

    enum SubscriptionStatus {
        None,
        Trialing,
        Active,
        Paused,
        Canceled,
        PastDue,
        PendingPause
    }

    enum ManagerCommand {
        None,
        PlanChange,
        Cancel,
        PastDue,
        Renew,
        ClearDiscount,
        Pause
    }

    struct Subscription {
        bytes32 planData;
        bytes32 networkData;
        bytes32 discountId;
        bytes32 discountData;
        bytes32 ref;
        address provider;
        SubscriptionStatus status;
        uint32 planId;
        uint32 createdAt;
        uint32 renewAt;
        uint32 minTermAt;
        uint32 cancelAt;
        string cid;
        string dataCid;
    }

    struct PlanInfo {
        uint256 price;
        uint32 planId;
        uint32 period;
        uint32 freeTrial;
        uint32 maxActive;
        uint16 minPeriods;
        uint8 gracePeriod;
        bool canPause;
        bool canTransfer;
    }

    struct NetworkInfo {
        address network;
        uint16 feeBps;
    }

    /************************** SUBSCRIPTION INSTANCE METHODS **************************/

    function createSubscription(
        uint256 _nonce,
        bytes32[] calldata _planProof,
        bytes32[] calldata _discountProof,
        uint32 _cancelAt,
        bytes memory _providerSignature,
        string calldata _cid
    ) external;

    function createNetworkSubscription(
        uint256 _nonce,
        bytes32[] calldata _planProof,
        bytes32[] calldata _discountProof,
        bytes32 _networkData,
        uint32 _cancelAt,
        bytes memory _providerSignature,
        bytes memory _networkSignature,
        string calldata _cid
    ) external;

    function changeSubscriptionPlan(
        uint256 _subscriptionId,
        uint256 _nonce,
        bytes32[] calldata _planProof,
        bytes32[] calldata _discountProof,
        bytes memory _providerSignature,
        string calldata _cid
    ) external;

    function attachData(uint256 _subscriptionId, string calldata _dataCid) external;

    function pauseSubscription(uint256 _subscriptionId) external;

    function resumeSubscription(uint256 _subscriptionId) external;

    function cancelSubscription(uint256 _subscriptionId, uint32 _cancelAt) external;

    function managerCommand(uint256 _subscriptionId, ManagerCommand _command) external;

    function getSubscription(uint256 _subscriptionId) external view returns
        (Subscription memory subscription, address currentOwner);

    function getConsumerSubscription(address _consumer, uint256 _idx) external view returns(uint256);

    function getConsumerSubscriptionCount(address _consumer) external view returns (uint256);

    function getProviderSubscription(address _provider, uint256 _idx) external view returns(uint256);

    function getProviderSubscriptionCount(address _provider, bool _includeCanceled, uint32 _planId) external view returns (uint256);

    function getActiveSubscriptionCount(address _consumer, address _provider, uint32 _planId) external view returns(uint256);

    function getPendingPlanChange(uint256 _subscriptionId) external view returns (bytes32);


    /************************** SUBSCRIPTION EVENTS **************************/

    /** @dev Emitted when `consumer` subscribes to `provider` plan `planId` */
    event SubscriptionCreated(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId, bytes32 discountId);

    /** @dev Emitted when `consumer` changes the plan to `provider` on subscription `subscriptionId` */
    event SubscriptionChangedPlan(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 prevPlanId, uint32 planId, bytes32 discountId);

    /** @dev Emitted when `consumer` changes the plan to `provider` on subscription `subscriptionId` */
    event SubscriptionPendingChangePlan(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 prevPlanId, uint32 planId);

    /** @dev Emitted when `consumer` initiates a pause of the subscription to `provider` on subscription `subscriptionId` */
    event SubscriptionPendingPause(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId);

    /** @dev Emitted when a pending pause subscription attempts to renew but is paused */
    event SubscriptionPaused(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId);

    /** @dev Emitted when `consumer` resumes the subscription to `provider` on subscription `subscriptionId` */
    event SubscriptionResumed(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId);

    /** @dev Emitted when `consumer` unsubscribes to `provider` on subscription `subscriptionId` */
    event SubscriptionPendingCancel(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId, uint32 cancelAt);

    /** @dev Emitted when `consumer` has canceled and the current period is over on subscription `subscriptionId` */
    event SubscriptionCanceled(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId);

    /** @dev Emitted when `consumer` successfully renews to `provider` on subscription `subscriptionId` */
    event SubscriptionRenewed(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId);

    /** @dev Emitted when `consumer` subscription trial ends and goes active to `provider`
     * on subscription `subscriptionId`
     */
    event SubscriptionTrialEnded(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId);

    /** @dev Emitted when `consumer` renewal fails to `provider` on subscription `subscriptionId` */
    event SubscriptionPastDue(address indexed consumer, address indexed provider,
        uint256 indexed subscriptionId, bytes32 ref, uint32 planId);

}