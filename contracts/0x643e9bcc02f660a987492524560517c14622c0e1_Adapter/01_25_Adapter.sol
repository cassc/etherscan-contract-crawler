// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20, Address} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IAdapter} from "./interfaces/IAdapter.sol";
import {IAdapterOwner} from "./interfaces/IAdapterOwner.sol";
import {IController} from "./interfaces/IController.sol";
import {IBasicRandcastConsumerBase} from "./interfaces/IBasicRandcastConsumerBase.sol";
import {RequestIdBase} from "./utils/RequestIdBase.sol";
import {RandomnessHandler} from "./utils/RandomnessHandler.sol";
import {BLS} from "./libraries/BLS.sol";
// solhint-disable-next-line no-global-import
import "./utils/Utils.sol" as Utils;

contract Adapter is UUPSUpgradeable, IAdapter, IAdapterOwner, RequestIdBase, RandomnessHandler, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    // *Constants*
    uint16 public constant MAX_CONSUMERS = 100;
    uint16 public constant MAX_REQUEST_CONFIRMATIONS = 200;
    uint32 public constant RANDOMNESS_REWARD_GAS = 9000;
    uint32 public constant VERIFICATION_GAS_OVER_MINIMUM_THRESHOLD = 50000;
    uint32 public constant DEFAULT_MINIMUM_THRESHOLD = 3;

    // *State Variables*
    IController internal _controller;
    uint256 internal _cumulativeFlatFee;
    uint256 internal _cumulativeCommitterReward;
    uint256 internal _cumulativePartialSignatureReward;

    // Randomness Task State
    uint32 internal _lastAssignedGroupIndex;
    uint256 internal _lastRandomness;
    uint256 internal _randomnessCount;

    AdapterConfig internal _config;
    mapping(bytes32 => bytes32) internal _requestCommitments;
    /* consumerAddress - consumer */
    mapping(address => Consumer) internal _consumers;
    /* subId - subscription */
    mapping(uint64 => Subscription) internal _subscriptions;
    uint64 internal _currentSubId;

    // Referral Promotion
    ReferralConfig internal _referralConfig;

    // Flat Fee Promotion
    FlatFeeConfig internal _flatFeeConfig;

    // *Structs*
    // Note a nonce of 0 indicates an the consumer is not assigned to that subscription.
    struct Consumer {
        /* subId - nonce */
        mapping(uint64 => uint64) nonces;
        uint64 lastSubscription;
    }

    struct Subscription {
        address owner; // Owner can fund/withdraw/cancel the sub.
        address requestedOwner; // For safely transferring sub ownership.
        address[] consumers;
        uint256 balance; // Token balance used for all consumer requests.
        uint256 inflightCost; // Upper cost for pending requests(except drastic exchange rate changes).
        mapping(bytes32 => uint256) inflightPayments;
        uint64 reqCount; // For fee tiers
        uint64 freeRequestCount; // Number of free requests(flat fee) for this sub.
        uint64 referralSubId; //
        uint64 reqCountInCurrentPeriod;
        // Number of requests in the current period.
        uint256 lastRequestTimestamp; // Timestamp of the last request.
    }

    // *Events*
    event AdapterConfigSet(
        uint16 minimumRequestConfirmations,
        uint32 maxGasLimit,
        uint32 gasAfterPaymentCalculation,
        uint32 gasExceptCallback,
        uint256 signatureTaskExclusiveWindow,
        uint256 rewardPerSignature,
        uint256 committerRewardPerSignature
    );
    event FlatFeeConfigSet(
        FeeConfig flatFeeConfig,
        uint16 flatFeePromotionGlobalPercentage,
        bool isFlatFeePromotionEnabledPermanently,
        uint256 flatFeePromotionStartTimestamp,
        uint256 flatFeePromotionEndTimestamp
    );
    event ReferralConfigSet(
        bool isReferralEnabled, uint16 freeRequestCountForReferrer, uint16 freeRequestCountForReferee
    );
    event SubscriptionCreated(uint64 indexed subId, address indexed owner);
    event SubscriptionFunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);
    event SubscriptionConsumerAdded(uint64 indexed subId, address consumer);
    event SubscriptionReferralSet(uint64 indexed subId, uint64 indexed referralSubId);
    event SubscriptionCanceled(uint64 indexed subId, address to, uint256 amount);
    event SubscriptionConsumerRemoved(uint64 indexed subId, address consumer);
    event RandomnessRequest(
        bytes32 indexed requestId,
        uint64 indexed subId,
        uint32 indexed groupIndex,
        RequestType requestType,
        bytes params,
        address sender,
        uint256 seed,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint256 callbackMaxGasPrice,
        uint256 estimatedPayment
    );
    event RandomnessRequestResult(
        bytes32 indexed requestId,
        uint32 indexed groupIndex,
        address indexed committer,
        address[] participantMembers,
        uint256 randommness,
        uint256 payment,
        uint256 flatFee,
        bool success
    );

    // *Errors*
    error Reentrant();
    error InvalidRequestConfirmations(uint16 have, uint16 min, uint16 max);
    error TooManyConsumers();
    error InsufficientBalanceWhenRequest();
    error InsufficientBalanceWhenFulfill();
    error InvalidConsumer(uint64 subId, address consumer);
    error InvalidSubscription();
    error ReferralPromotionDisabled();
    error SubscriptionAlreadyHasReferral();
    error IdenticalSubscription();
    error AtLeastOneRequestIsRequired();
    error MustBeSubOwner(address owner);
    error PaymentTooLarge();
    error NoAvailableGroups();
    error NoCorrespondingRequest();
    error IncorrectCommitment();
    error InvalidRequestByEOA();
    error TaskStillExclusive();
    error TaskStillWithinRequestConfirmations();
    error NotFromCommitter();
    error GroupNotExist(uint256 groupIndex);
    error SenderNotController();
    error PendingRequestExists();
    error InvalidZeroAddress();
    error GasLimitTooBig(uint32 have, uint32 want);

    // *Modifiers*
    modifier onlySubOwner(uint64 subId) {
        address owner = _subscriptions[subId].owner;
        if (owner == address(0)) {
            revert InvalidSubscription();
        }
        if (msg.sender != owner) {
            revert MustBeSubOwner(owner);
        }
        _;
    }

    modifier nonReentrant() {
        if (_config.reentrancyLock) {
            revert Reentrant();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address controller) public initializer {
        _controller = IController(controller);

        __Ownable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // =============
    // IAdapterOwner
    // =============
    function setAdapterConfig(
        uint16 minimumRequestConfirmations,
        uint32 maxGasLimit,
        uint32 gasAfterPaymentCalculation,
        uint32 gasExceptCallback,
        uint256 signatureTaskExclusiveWindow,
        uint256 rewardPerSignature,
        uint256 committerRewardPerSignature
    ) external override(IAdapterOwner) onlyOwner {
        if (minimumRequestConfirmations > MAX_REQUEST_CONFIRMATIONS) {
            revert InvalidRequestConfirmations(
                minimumRequestConfirmations, minimumRequestConfirmations, MAX_REQUEST_CONFIRMATIONS
            );
        }
        _config = AdapterConfig({
            minimumRequestConfirmations: minimumRequestConfirmations,
            maxGasLimit: maxGasLimit,
            gasAfterPaymentCalculation: gasAfterPaymentCalculation,
            gasExceptCallback: gasExceptCallback,
            signatureTaskExclusiveWindow: signatureTaskExclusiveWindow,
            rewardPerSignature: rewardPerSignature,
            committerRewardPerSignature: committerRewardPerSignature,
            reentrancyLock: false
        });

        emit AdapterConfigSet(
            minimumRequestConfirmations,
            maxGasLimit,
            gasAfterPaymentCalculation,
            gasExceptCallback,
            signatureTaskExclusiveWindow,
            rewardPerSignature,
            committerRewardPerSignature
        );
    }

    function setFlatFeeConfig(
        FeeConfig memory flatFeeConfig,
        uint16 flatFeePromotionGlobalPercentage,
        bool isFlatFeePromotionEnabledPermanently,
        uint256 flatFeePromotionStartTimestamp,
        uint256 flatFeePromotionEndTimestamp
    ) external override(IAdapterOwner) onlyOwner {
        _flatFeeConfig = FlatFeeConfig({
            config: flatFeeConfig,
            flatFeePromotionGlobalPercentage: flatFeePromotionGlobalPercentage,
            isFlatFeePromotionEnabledPermanently: isFlatFeePromotionEnabledPermanently,
            flatFeePromotionStartTimestamp: flatFeePromotionStartTimestamp,
            flatFeePromotionEndTimestamp: flatFeePromotionEndTimestamp
        });

        emit FlatFeeConfigSet(
            flatFeeConfig,
            flatFeePromotionGlobalPercentage,
            isFlatFeePromotionEnabledPermanently,
            flatFeePromotionStartTimestamp,
            flatFeePromotionEndTimestamp
        );
    }

    function setReferralConfig(
        bool isReferralEnabled,
        uint16 freeRequestCountForReferrer,
        uint16 freeRequestCountForReferee
    ) external override(IAdapterOwner) onlyOwner {
        _referralConfig = ReferralConfig({
            isReferralEnabled: isReferralEnabled,
            freeRequestCountForReferrer: freeRequestCountForReferrer,
            freeRequestCountForReferee: freeRequestCountForReferee
        });

        emit ReferralConfigSet(isReferralEnabled, freeRequestCountForReferrer, freeRequestCountForReferee);
    }

    function setFreeRequestCount(uint64[] memory subIds, uint64[] memory freeRequestCounts)
        external
        override(IAdapterOwner)
        onlyOwner
    {
        for (uint256 i = 0; i < subIds.length; i++) {
            _subscriptions[subIds[i]].freeRequestCount = freeRequestCounts[i];
        }
    }

    function ownerCancelSubscription(uint64 subId) external override(IAdapterOwner) onlyOwner {
        if (_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        _cancelSubscriptionHelper(subId, _subscriptions[subId].owner);
    }

    // =============
    // IAdapter
    // =============
    function nodeWithdrawETH(address recipient, uint256 ethAmount) external {
        if (msg.sender != address(_controller)) {
            revert SenderNotController();
        }
        payable(recipient).transfer(ethAmount);
    }

    function createSubscription() external override(IAdapter) nonReentrant returns (uint64) {
        _currentSubId++;

        _subscriptions[_currentSubId].owner = msg.sender;
        // flat fee free for the first request for each subscription
        _subscriptions[_currentSubId].freeRequestCount = 1;

        emit SubscriptionCreated(_currentSubId, msg.sender);
        return _currentSubId;
    }

    function addConsumer(uint64 subId, address consumer) external override(IAdapter) onlySubOwner(subId) nonReentrant {
        // Already maxed, cannot add any more consumers.
        if (_subscriptions[subId].consumers.length == MAX_CONSUMERS) {
            revert TooManyConsumers();
        }
        if (_consumers[consumer].nonces[subId] != 0) {
            // Idempotence - do nothing if already added.
            // Ensures uniqueness in subscriptions[subId].consumers.
            return;
        }
        // Initialize the nonce to 1, indicating the consumer is allocated.
        _consumers[consumer].nonces[subId] = 1;
        _consumers[consumer].lastSubscription = subId;
        _subscriptions[subId].consumers.push(consumer);

        emit SubscriptionConsumerAdded(subId, consumer);
    }

    function removeConsumer(uint64 subId, address consumer) external override onlySubOwner(subId) nonReentrant {
        if (_subscriptions[subId].inflightCost != 0) {
            revert PendingRequestExists();
        }
        address[] memory consumers = _subscriptions[subId].consumers;
        if (consumers.length == 0) {
            revert InvalidConsumer(subId, consumer);
        }
        // Note bounded by MAX_CONSUMERS
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == consumer) {
                _subscriptions[subId].consumers[i] = consumers[consumers.length - 1];
                _subscriptions[subId].consumers.pop();

                emit SubscriptionConsumerRemoved(subId, consumer);
                return;
            }
        }
        revert InvalidConsumer(subId, consumer);
    }

    function fundSubscription(uint64 subId) external payable override(IAdapter) nonReentrant {
        if (_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }

        // We do not check that the msg.sender is the subscription owner,
        // anyone can fund a subscription.
        uint256 oldBalance = _subscriptions[subId].balance;
        _subscriptions[subId].balance += msg.value;
        emit SubscriptionFunded(subId, oldBalance, oldBalance + msg.value);
    }

    function setReferral(uint64 subId, uint64 referralSubId) external onlySubOwner(subId) nonReentrant {
        if (!_referralConfig.isReferralEnabled) {
            revert ReferralPromotionDisabled();
        }
        if (_subscriptions[subId].owner == _subscriptions[referralSubId].owner) {
            revert IdenticalSubscription();
        }
        if (_subscriptions[subId].referralSubId != 0) {
            revert SubscriptionAlreadyHasReferral();
        }
        if (_subscriptions[subId].reqCount == 0 || _subscriptions[referralSubId].reqCount == 0) {
            revert AtLeastOneRequestIsRequired();
        }
        _subscriptions[referralSubId].freeRequestCount += _referralConfig.freeRequestCountForReferrer;
        _subscriptions[subId].freeRequestCount += _referralConfig.freeRequestCountForReferee;
        _subscriptions[subId].referralSubId = referralSubId;

        emit SubscriptionReferralSet(subId, referralSubId);
    }

    function cancelSubscription(uint64 subId, address to) external override onlySubOwner(subId) nonReentrant {
        if (to == address(0)) {
            revert InvalidZeroAddress();
        }
        if (_subscriptions[subId].inflightCost != 0) {
            revert PendingRequestExists();
        }
        _cancelSubscriptionHelper(subId, to);
    }

    function requestRandomness(RandomnessRequestParams calldata params)
        public
        virtual
        override(IAdapter)
        nonReentrant
        returns (bytes32)
    {
        RandomnessRequestParams memory p = params;

        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin) {
            revert InvalidRequestByEOA();
        }

        Subscription storage sub = _subscriptions[p.subId];

        // Input validation using the subscription storage.
        if (sub.owner == address(0)) {
            revert InvalidSubscription();
        }
        // Its important to ensure that the consumer is in fact who they say they
        // are, otherwise they could use someone else's subscription balance.
        // A nonce of 0 indicates consumer is not allocated to the sub.
        if (_consumers[msg.sender].nonces[p.subId] == 0) {
            revert InvalidConsumer(p.subId, msg.sender);
        }

        if (
            p.requestConfirmations < _config.minimumRequestConfirmations
                || p.requestConfirmations > MAX_REQUEST_CONFIRMATIONS
        ) {
            revert InvalidRequestConfirmations(
                p.requestConfirmations, _config.minimumRequestConfirmations, MAX_REQUEST_CONFIRMATIONS
            );
        }
        // No lower bound on the requested gas limit. A user could request 0
        // and they would simply be billed for the proof verification and wouldn't be
        // able to do anything with the random value.
        if (p.callbackGasLimit > _config.maxGasLimit) {
            revert GasLimitTooBig(p.callbackGasLimit, _config.maxGasLimit);
        }

        // Choose current available group to handle randomness request(by round robin)
        _lastAssignedGroupIndex = uint32(_findGroupToAssignTask());

        // Calculate requestId for the task
        uint256 rawSeed = _makeRandcastInputSeed(p.seed, msg.sender, _consumers[msg.sender].nonces[p.subId]);
        _consumers[msg.sender].nonces[p.subId] += 1;
        bytes32 requestId = _makeRequestId(rawSeed);

        (, uint256 groupSize) = _controller.getGroupThreshold(_lastAssignedGroupIndex);

        uint256 payment =
            _freezePaymentBySubscription(sub, requestId, uint32(groupSize), p.callbackGasLimit, p.callbackMaxGasPrice);

        _requestCommitments[requestId] = keccak256(
            abi.encode(
                requestId,
                p.subId,
                _lastAssignedGroupIndex,
                p.requestType,
                p.params,
                msg.sender,
                rawSeed,
                p.requestConfirmations,
                p.callbackGasLimit,
                p.callbackMaxGasPrice,
                block.number
            )
        );

        emit RandomnessRequest(
            requestId,
            p.subId,
            _lastAssignedGroupIndex,
            p.requestType,
            p.params,
            msg.sender,
            rawSeed,
            p.requestConfirmations,
            p.callbackGasLimit,
            p.callbackMaxGasPrice,
            payment
        );

        return requestId;
    }

    function fulfillRandomness(
        uint32 groupIndex,
        bytes32 requestId,
        uint256 signature,
        RequestDetail calldata requestDetail,
        PartialSignature[] calldata partialSignatures
    ) public virtual override(IAdapter) nonReentrant {
        uint256 startGas = gasleft();

        bytes32 commitment = _requestCommitments[requestId];
        if (commitment == 0) {
            revert NoCorrespondingRequest();
        }
        if (
            commitment
                != keccak256(
                    abi.encode(
                        requestId,
                        requestDetail.subId,
                        requestDetail.groupIndex,
                        requestDetail.requestType,
                        requestDetail.params,
                        requestDetail.callbackContract,
                        requestDetail.seed,
                        requestDetail.requestConfirmations,
                        requestDetail.callbackGasLimit,
                        requestDetail.callbackMaxGasPrice,
                        requestDetail.blockNum
                    )
                )
        ) {
            revert IncorrectCommitment();
        }

        if (block.number < requestDetail.blockNum + requestDetail.requestConfirmations) {
            revert TaskStillWithinRequestConfirmations();
        }

        if (
            groupIndex != requestDetail.groupIndex
                && block.number <= requestDetail.blockNum + _config.signatureTaskExclusiveWindow
        ) {
            revert TaskStillExclusive();
        }
        if (groupIndex >= _controller.getGroupCount()) {
            revert GroupNotExist(groupIndex);
        }

        address[] memory participantMembers =
            _verifySignature(groupIndex, requestDetail.seed, requestDetail.blockNum, signature, partialSignatures);

        delete _requestCommitments[requestId];

        uint256 randomness = uint256(keccak256(abi.encode(signature)));

        _randomnessCount += 1;
        _lastRandomness = randomness;
        _controller.setLastOutput(randomness);
        // call user fulfill_randomness callback
        bool success = _fulfillCallback(requestId, randomness, requestDetail);

        (uint256 payment, uint256 flatFee) =
            _payBySubscription(_subscriptions[requestDetail.subId], requestId, partialSignatures.length, startGas);

        // rewardRandomness for participants
        _rewardRandomness(participantMembers, payment, flatFee);

        // Include payment in the event for tracking costs.
        emit RandomnessRequestResult(
            requestId, groupIndex, msg.sender, participantMembers, randomness, payment, flatFee, success
        );
    }

    function getLastSubscription(address consumer) public view override(IAdapter) returns (uint64) {
        return _consumers[consumer].lastSubscription;
    }

    function getSubscription(uint64 subId)
        external
        view
        returns (
            address owner,
            address[] memory consumers,
            uint256 balance,
            uint256 inflightCost,
            uint64 reqCount,
            uint64 freeRequestCount,
            uint64 referralSubId,
            uint64 reqCountInCurrentPeriod,
            uint256 lastRequestTimestamp
        )
    {
        Subscription storage sub = _subscriptions[subId];
        if (sub.owner == address(0)) {
            revert InvalidSubscription();
        }
        return (
            sub.owner,
            sub.consumers,
            sub.balance,
            sub.inflightCost,
            sub.reqCount,
            sub.freeRequestCount,
            sub.referralSubId,
            sub.reqCountInCurrentPeriod,
            sub.lastRequestTimestamp
        );
    }

    function getPendingRequestCommitment(bytes32 requestId) public view override(IAdapter) returns (bytes32) {
        return _requestCommitments[requestId];
    }

    function getLastAssignedGroupIndex() external view returns (uint256) {
        return _lastAssignedGroupIndex;
    }

    function getLastRandomness() external view override(IAdapter) returns (uint256) {
        return _lastRandomness;
    }

    function getRandomnessCount() external view override(IAdapter) returns (uint256) {
        return _randomnessCount;
    }

    function getCurrentSubId() external view returns (uint64) {
        return _currentSubId;
    }

    function getCumulativeData() external view returns (uint256, uint256, uint256) {
        return (_cumulativeFlatFee, _cumulativeCommitterReward, _cumulativePartialSignatureReward);
    }

    function getController() external view returns (address) {
        return address(_controller);
    }

    function getAdapterConfig()
        external
        view
        returns (
            uint16 minimumRequestConfirmations,
            uint32 maxGasLimit,
            uint32 gasAfterPaymentCalculation,
            uint32 gasExceptCallback,
            uint256 signatureTaskExclusiveWindow,
            uint256 rewardPerSignature,
            uint256 committerRewardPerSignature
        )
    {
        return (
            _config.minimumRequestConfirmations,
            _config.maxGasLimit,
            _config.gasAfterPaymentCalculation,
            _config.gasExceptCallback,
            _config.signatureTaskExclusiveWindow,
            _config.rewardPerSignature,
            _config.committerRewardPerSignature
        );
    }

    function getFlatFeeConfig()
        external
        view
        returns (
            uint32 fulfillmentFlatFeeLinkPPMTier1,
            uint32 fulfillmentFlatFeeLinkPPMTier2,
            uint32 fulfillmentFlatFeeLinkPPMTier3,
            uint32 fulfillmentFlatFeeLinkPPMTier4,
            uint32 fulfillmentFlatFeeLinkPPMTier5,
            uint24 reqsForTier2,
            uint24 reqsForTier3,
            uint24 reqsForTier4,
            uint24 reqsForTier5,
            uint16 flatFeePromotionGlobalPercentage,
            bool isFlatFeePromotionEnabledPermanently,
            uint256 flatFeePromotionStartTimestamp,
            uint256 flatFeePromotionEndTimestamp
        )
    {
        FeeConfig memory fc = _flatFeeConfig.config;
        return (
            fc.fulfillmentFlatFeeEthPPMTier1,
            fc.fulfillmentFlatFeeEthPPMTier2,
            fc.fulfillmentFlatFeeEthPPMTier3,
            fc.fulfillmentFlatFeeEthPPMTier4,
            fc.fulfillmentFlatFeeEthPPMTier5,
            fc.reqsForTier2,
            fc.reqsForTier3,
            fc.reqsForTier4,
            fc.reqsForTier5,
            _flatFeeConfig.flatFeePromotionGlobalPercentage,
            _flatFeeConfig.isFlatFeePromotionEnabledPermanently,
            _flatFeeConfig.flatFeePromotionStartTimestamp,
            _flatFeeConfig.flatFeePromotionEndTimestamp
        );
    }

    function getReferralConfig()
        external
        view
        returns (bool isReferralEnabled, uint16 freeRequestCountForReferrer, uint16 freeRequestCountForReferee)
    {
        return (
            _referralConfig.isReferralEnabled,
            _referralConfig.freeRequestCountForReferrer,
            _referralConfig.freeRequestCountForReferee
        );
    }

    function getFeeTier(uint64 reqCount) public view override(IAdapter) returns (uint32) {
        FeeConfig memory fc = _flatFeeConfig.config;
        if (reqCount <= fc.reqsForTier2) {
            return fc.fulfillmentFlatFeeEthPPMTier1;
        }
        if (fc.reqsForTier2 < reqCount && reqCount <= fc.reqsForTier3) {
            return fc.fulfillmentFlatFeeEthPPMTier2;
        }
        if (fc.reqsForTier3 < reqCount && reqCount <= fc.reqsForTier4) {
            return fc.fulfillmentFlatFeeEthPPMTier3;
        }
        if (fc.reqsForTier4 < reqCount && reqCount <= fc.reqsForTier5) {
            return fc.fulfillmentFlatFeeEthPPMTier4;
        }
        return fc.fulfillmentFlatFeeEthPPMTier5;
    }

    function estimatePaymentAmountInETH(
        uint32 callbackGasLimit,
        uint32 gasExceptCallback,
        uint32 fulfillmentFlatFeeEthPPM,
        uint256 weiPerUnitGas
    ) public pure override(IAdapter) returns (uint256) {
        uint256 paymentNoFee = weiPerUnitGas * (gasExceptCallback + callbackGasLimit);
        return (paymentNoFee + 1e12 * uint256(fulfillmentFlatFeeEthPPM));
    }

    // =============
    // Internal
    // =============

    function _rewardRandomness(address[] memory participantMembers, uint256 payment, uint256 flatFee) internal {
        _cumulativeCommitterReward += _config.committerRewardPerSignature;
        _cumulativePartialSignatureReward += _config.rewardPerSignature * participantMembers.length;

        address[] memory committer = new address[](1);
        committer[0] = msg.sender;
        _controller.addReward(committer, payment - flatFee, _config.committerRewardPerSignature);
        _controller.addReward(participantMembers, flatFee / participantMembers.length, _config.rewardPerSignature);
    }

    function _fulfillCallback(bytes32 requestId, uint256 randomness, RequestDetail memory requestDetail)
        internal
        returns (bool success)
    {
        IBasicRandcastConsumerBase b;
        bytes memory resp;
        if (requestDetail.requestType == RequestType.Randomness) {
            resp = abi.encodeWithSelector(b.rawFulfillRandomness.selector, requestId, randomness);
        } else if (requestDetail.requestType == RequestType.RandomWords) {
            uint32 numWords = abi.decode(requestDetail.params, (uint32));
            uint256[] memory randomWords = new uint256[](numWords);
            for (uint256 i = 0; i < numWords; i++) {
                randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
            }
            resp = abi.encodeWithSelector(b.rawFulfillRandomWords.selector, requestId, randomWords);
        } else if (requestDetail.requestType == RequestType.Shuffling) {
            uint32 upper = abi.decode(requestDetail.params, (uint32));
            uint256[] memory shuffledArray = _shuffle(upper, randomness);
            resp = abi.encodeWithSelector(b.rawFulfillShuffledArray.selector, requestId, shuffledArray);
        }

        // Call with explicitly the amount of callback gas requested
        // Important to not let them exhaust the gas budget and avoid oracle payment.
        // Do not allow any non-view/non-pure coordinator functions to be called
        // during the consumers callback code via reentrancyLock.
        // Note that callWithExactGas will revert if we do not have sufficient gas
        // to give the callee their requested amount.
        _config.reentrancyLock = true;
        success = Utils.callWithExactGas(requestDetail.callbackGasLimit, requestDetail.callbackContract, resp);
        _config.reentrancyLock = false;
    }

    function _freezePaymentBySubscription(
        Subscription storage sub,
        bytes32 requestId,
        uint32 groupSize,
        uint32 callbackGasLimit,
        uint256 callbackMaxGasPrice
    ) internal returns (uint256) {
        uint64 reqCount;
        if (_flatFeeConfig.isFlatFeePromotionEnabledPermanently) {
            reqCount = sub.reqCount;
        } else if (
            _flatFeeConfig
                //solhint-disable-next-line not-rely-on-time
                .flatFeePromotionStartTimestamp <= block.timestamp
            //solhint-disable-next-line not-rely-on-time
            && block.timestamp <= _flatFeeConfig.flatFeePromotionEndTimestamp
        ) {
            if (sub.lastRequestTimestamp < _flatFeeConfig.flatFeePromotionStartTimestamp) {
                reqCount = 1;
            } else {
                reqCount = sub.reqCountInCurrentPeriod + 1;
            }
        }

        // Estimate upper cost of this fulfillment.
        uint256 payment = estimatePaymentAmountInETH(
            callbackGasLimit,
            _config.gasExceptCallback + RANDOMNESS_REWARD_GAS * groupSize
                + VERIFICATION_GAS_OVER_MINIMUM_THRESHOLD * (groupSize - DEFAULT_MINIMUM_THRESHOLD),
            sub.freeRequestCount > 0
                ? 0
                : (getFeeTier(reqCount) * _flatFeeConfig.flatFeePromotionGlobalPercentage / 100),
            callbackMaxGasPrice
        );

        if (sub.balance - sub.inflightCost < payment) {
            revert InsufficientBalanceWhenRequest();
        }

        sub.inflightCost += payment;
        sub.inflightPayments[requestId] = payment;

        return payment;
    }

    function _payBySubscription(
        Subscription storage sub,
        bytes32 requestId,
        uint256 partialSignersCount,
        uint256 startGas
    ) internal returns (uint256, uint256) {
        // Increment the req count for fee tier selection.
        sub.reqCount += 1;
        uint64 reqCount;
        if (_flatFeeConfig.isFlatFeePromotionEnabledPermanently) {
            reqCount = sub.reqCount;
        } else if (
            _flatFeeConfig
                //solhint-disable-next-line not-rely-on-time
                .flatFeePromotionStartTimestamp <= block.timestamp
            //solhint-disable-next-line not-rely-on-time
            && block.timestamp <= _flatFeeConfig.flatFeePromotionEndTimestamp
        ) {
            if (sub.lastRequestTimestamp < _flatFeeConfig.flatFeePromotionStartTimestamp) {
                sub.reqCountInCurrentPeriod = 1;
            } else {
                sub.reqCountInCurrentPeriod += 1;
            }
            reqCount = sub.reqCountInCurrentPeriod;
        }

        //solhint-disable-next-line not-rely-on-time
        sub.lastRequestTimestamp = block.timestamp;

        uint256 flatFee;
        if (sub.freeRequestCount > 0) {
            sub.freeRequestCount -= 1;
        } else {
            // The flat eth fee is specified in millionths of eth, if _config.fulfillmentFlatFeeEthPPM = 1
            // 1 eth / 1e6 = 1e18 eth wei / 1e6 = 1e12 eth wei.
            flatFee = 1e12 * uint256(getFeeTier(reqCount)) * _flatFeeConfig.flatFeePromotionGlobalPercentage / 100;
        }

        // We want to charge users exactly for how much gas they use in their callback.
        // The gasAfterPaymentCalculation is meant to cover these additional operations where we
        // decrement the subscription balance and increment the groups withdrawable balance.
        uint256 payment = _calculatePaymentAmountInETH(
            startGas,
            _config.gasAfterPaymentCalculation + RANDOMNESS_REWARD_GAS * partialSignersCount,
            flatFee,
            tx.gasprice
        );

        if (sub.balance < payment) {
            revert InsufficientBalanceWhenFulfill();
        }
        sub.inflightCost -= sub.inflightPayments[requestId];
        delete sub.inflightPayments[requestId];
        sub.balance -= payment;

        _cumulativeFlatFee += flatFee;

        return (payment, flatFee);
    }

    function _cancelSubscriptionHelper(uint64 subId, address to) internal nonReentrant {
        uint256 balance = _subscriptions[subId].balance;
        delete _subscriptions[subId].owner;
        emit SubscriptionCanceled(subId, to, balance);
        payable(to).transfer(balance);
    }

    // Get the amount of gas used for fulfillment
    function _calculatePaymentAmountInETH(
        uint256 startGas,
        uint256 gasAfterPaymentCalculation,
        uint256 flatFee,
        uint256 weiPerUnitGas
    ) internal view returns (uint256) {
        uint256 paymentNoFee = weiPerUnitGas * (gasAfterPaymentCalculation + startGas - gasleft());
        if (paymentNoFee > (12e25 - flatFee)) {
            revert PaymentTooLarge(); // Payment + flatFee cannot be more than all of the ETH in existence.
        }
        return paymentNoFee + flatFee;
    }

    function _findGroupToAssignTask() internal view returns (uint256) {
        uint256[] memory validGroupIndices = _controller.getValidGroupIndices();

        if (validGroupIndices.length == 0) {
            revert NoAvailableGroups();
        }

        uint256 groupCount = _controller.getGroupCount();

        uint256 currentAssignedGroupIndex = (_lastAssignedGroupIndex + 1) % groupCount;

        while (!Utils.containElement(validGroupIndices, currentAssignedGroupIndex)) {
            currentAssignedGroupIndex = (currentAssignedGroupIndex + 1) % groupCount;
        }

        return currentAssignedGroupIndex;
    }

    function _verifySignature(
        uint256 groupIndex,
        uint256 seed,
        uint256 blockNum,
        uint256 signature,
        PartialSignature[] memory partialSignatures
    ) internal view returns (address[] memory participantMembers) {
        if (!BLS.isValid(signature)) {
            revert BLS.InvalidSignatureFormat();
        }

        if (partialSignatures.length == 0) {
            revert BLS.EmptyPartialSignatures();
        }

        IController.Group memory g = _controller.getGroup(groupIndex);

        if (!Utils.containElement(g.committers, msg.sender)) {
            revert NotFromCommitter();
        }

        bytes memory actualSeed = abi.encodePacked(seed, blockNum);

        uint256[2] memory message = BLS.hashToPoint(actualSeed);

        // verify tss-aggregation signature for randomness
        if (!BLS.verifySingle(BLS.decompress(signature), g.publicKey, message)) {
            revert BLS.InvalidSignature();
        }

        // verify bls-aggregation signature for incentivizing worker list
        uint256[2][] memory partials = new uint256[2][](partialSignatures.length);
        uint256[4][] memory pubkeys = new uint256[4][](partialSignatures.length);
        participantMembers = new address[](partialSignatures.length);
        for (uint256 i = 0; i < partialSignatures.length; i++) {
            if (!BLS.isValid(partialSignatures[i].partialSignature)) {
                revert BLS.InvalidPartialSignatureFormat();
            }
            partials[i] = BLS.decompress(partialSignatures[i].partialSignature);
            pubkeys[i] = g.members[partialSignatures[i].index].partialPublicKey;
            participantMembers[i] = g.members[partialSignatures[i].index].nodeIdAddress;
        }
        if (!BLS.verifyPartials(partials, pubkeys, message)) {
            revert BLS.InvalidPartialSignatures();
        }
    }
}