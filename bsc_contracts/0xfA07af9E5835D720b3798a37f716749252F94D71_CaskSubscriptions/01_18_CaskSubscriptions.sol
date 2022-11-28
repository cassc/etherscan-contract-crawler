// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@opengsn/contracts/src/BaseRelayRecipient.sol";


import "../interfaces/ICaskSubscriptionManager.sol";
import "../interfaces/ICaskSubscriptions.sol";
import "../interfaces/ICaskSubscriptionPlans.sol";

contract CaskSubscriptions is
ICaskSubscriptions,
BaseRelayRecipient,
ERC721Upgradeable,
OwnableUpgradeable,
PausableUpgradeable
{

    /************************** PARAMETERS **************************/

    /** @dev contract to manage subscription plan definitions. */
    ICaskSubscriptionManager public subscriptionManager;

    /** @dev contract to manage subscription plan definitions. */
    ICaskSubscriptionPlans public subscriptionPlans;


    /************************** STATE **************************/

    /** @dev Maps for consumer to list of subscriptions. */
    mapping(address => uint256[]) private consumerSubscriptions; // consumer => subscriptionId[]
    mapping(uint256 => Subscription) private subscriptions; // subscriptionId => Subscription
    mapping(uint256 => bytes32) private pendingPlanChanges; // subscriptionId => planData

    /** @dev Maps for provider to list of subscriptions and plans. */
    mapping(address => uint256[]) private providerSubscriptions; // provider => subscriptionId[]
    mapping(address => uint256) private providerActiveSubscriptionCount; // provider => count
    mapping(address => mapping(uint32 => uint256)) private planActiveSubscriptionCount; // provider => planId => count
    mapping(address => mapping(address => mapping(uint32 => uint256))) private consumerProviderPlanActiveCount;

    modifier onlyManager() {
        require(_msgSender() == address(subscriptionManager), "!AUTH");
        _;
    }

    modifier onlySubscriber(uint256 _subscriptionId) {
        require(_msgSender() == ownerOf(_subscriptionId), "!AUTH");
        _;
    }

    modifier onlySubscriberOrProvider(uint256 _subscriptionId) {
        require(
            _msgSender() == ownerOf(_subscriptionId) ||
            _msgSender() == subscriptions[_subscriptionId].provider,
            "!AUTH"
        );
        _;
    }

    function initialize(
        address _subscriptionPlans
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC721_init("Cask Subscriptions","CASKSUBS");

        subscriptionPlans = ICaskSubscriptionPlans(_subscriptionPlans);
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function versionRecipient() public pure override returns(string memory) { return "2.2.0"; }

    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }


    function tokenURI(uint256 _subscriptionId) public view override returns (string memory) {
        require(_exists(_subscriptionId), "ERC721Metadata: URI query for nonexistent token");

        Subscription memory subscription = subscriptions[_subscriptionId];

        return string(abi.encodePacked("ipfs://", subscription.cid));
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _subscriptionId
    ) internal override {
        if (_from != address(0) && _to != address(0)) { // only non-mint/burn transfers
            Subscription storage subscription = subscriptions[_subscriptionId];

            PlanInfo memory planInfo = _parsePlanData(subscription.planData);
            require(planInfo.canTransfer, "!NOT_TRANSFERRABLE");

            require(subscription.minTermAt == 0 || uint32(block.timestamp) >= subscription.minTermAt, "!MIN_TERM");

            // on transfer, set subscription to cancel at next renewal until new owner accepts subscription
            subscription.cancelAt = subscription.renewAt;
            consumerSubscriptions[_to].push(_subscriptionId);
        }
    }

    /************************** SUBSCRIPTION METHODS **************************/

    function createNetworkSubscription(
        uint256 _nonce,
        bytes32[] calldata _planProof,  // [provider, ref, planData, merkleRoot, merkleProof...]
        bytes32[] calldata _discountProof, // [discountCodeProof, discountData, merkleRoot, merkleProof...]
        bytes32 _networkData,
        uint32 _cancelAt,
        bytes memory _providerSignature,
        bytes memory _networkSignature,
        string calldata _cid
    ) external override whenNotPaused {
        uint256 subscriptionId = _createSubscription(_nonce, _planProof, _discountProof, _cancelAt,
            _providerSignature, _cid);

        _verifyNetworkData(_networkData, _networkSignature);

        Subscription storage subscription = subscriptions[subscriptionId];
        subscription.networkData = _networkData;
    }

    function createSubscription(
        uint256 _nonce,
        bytes32[] calldata _planProof, // [provider, ref, planData, merkleRoot, merkleProof...]
        bytes32[] calldata _discountProof, // [discountCodeProof, discountData, merkleRoot, merkleProof...]
        uint32 _cancelAt,
        bytes memory _providerSignature,
        string calldata _cid
    ) external override whenNotPaused {
        _createSubscription(_nonce, _planProof, _discountProof, _cancelAt, _providerSignature, _cid);
    }

    function attachData(
        uint256 _subscriptionId,
        string calldata _dataCid
    ) external override onlySubscriberOrProvider(_subscriptionId) whenNotPaused {
        Subscription storage subscription = subscriptions[_subscriptionId];
        require(subscription.status != SubscriptionStatus.Canceled, "!CANCELED");
        subscription.dataCid = _dataCid;
    }

    function changeSubscriptionPlan(
        uint256 _subscriptionId,
        uint256 _nonce,
        bytes32[] calldata _planProof,  // [provider, ref, planData, merkleRoot, merkleProof...]
        bytes32[] calldata _discountProof, // [discountCodeProof, discountData, merkleRoot, merkleProof...]
        bytes memory _providerSignature,
        string calldata _cid
    ) external override onlySubscriber(_subscriptionId) whenNotPaused {
        _changeSubscriptionPlan(_subscriptionId, _nonce, _planProof, _discountProof, _providerSignature, _cid);
    }

    function pauseSubscription(
        uint256 _subscriptionId
    ) external override onlySubscriberOrProvider(_subscriptionId) whenNotPaused {

        Subscription storage subscription = subscriptions[_subscriptionId];

        require(subscription.status != SubscriptionStatus.Paused &&
                subscription.status != SubscriptionStatus.PastDue &&
                subscription.status != SubscriptionStatus.Canceled &&
                subscription.status != SubscriptionStatus.Trialing, "!INVALID(status)");

        require(subscription.minTermAt == 0 || uint32(block.timestamp) >= subscription.minTermAt, "!MIN_TERM");

        PlanInfo memory planInfo = _parsePlanData(subscription.planData);
        require(planInfo.canPause, "!NOT_PAUSABLE");

        subscription.status = SubscriptionStatus.PendingPause;

        emit SubscriptionPendingPause(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
            subscription.ref, subscription.planId);
    }

    function resumeSubscription(
        uint256 _subscriptionId
    ) external override onlySubscriber(_subscriptionId) whenNotPaused {

        Subscription storage subscription = subscriptions[_subscriptionId];

        require(subscription.status == SubscriptionStatus.Paused ||
                subscription.status == SubscriptionStatus.PendingPause, "!NOT_PAUSED");

        emit SubscriptionResumed(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
            subscription.ref, subscription.planId);

        if (subscription.status == SubscriptionStatus.PendingPause) {
            subscription.status = SubscriptionStatus.Active;
            return;
        }

        PlanInfo memory planInfo = _parsePlanData(subscription.planData);

        require(planInfo.maxActive == 0 ||
            planActiveSubscriptionCount[subscription.provider][planInfo.planId] < planInfo.maxActive, "!MAX_ACTIVE");

        subscription.status = SubscriptionStatus.Active;

        providerActiveSubscriptionCount[subscription.provider] += 1;
        planActiveSubscriptionCount[subscription.provider][subscription.planId] += 1;
        consumerProviderPlanActiveCount[ownerOf(_subscriptionId)][subscription.provider][subscription.planId] += 1;

        // if renewal date has already passed, set it to now so consumer is not charged for the time it was paused
        if (subscription.renewAt < uint32(block.timestamp)) {
            subscription.renewAt = uint32(block.timestamp);
        }

        // re-register subscription with manager
        subscriptionManager.renewSubscription(_subscriptionId);

        // make sure still active if payment was required to resume
        require(subscription.status == SubscriptionStatus.Active, "!INSUFFICIENT_FUNDS");
    }

    function cancelSubscription(
        uint256 _subscriptionId,
        uint32 _cancelAt
    ) external override onlySubscriberOrProvider(_subscriptionId) whenNotPaused {

        Subscription storage subscription = subscriptions[_subscriptionId];

        require(subscription.status != SubscriptionStatus.Canceled, "!INVALID(status)");

        uint32 timestamp = uint32(block.timestamp);

        if(_cancelAt == 0) {
            require(_msgSender() == ownerOf(_subscriptionId), "!AUTH"); // clearing cancel only allowed by subscriber
            subscription.cancelAt = _cancelAt;

            emit SubscriptionPendingCancel(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
                subscription.ref, subscription.planId, _cancelAt);
        } else if(_cancelAt <= timestamp) {
            require(subscription.minTermAt == 0 || timestamp >= subscription.minTermAt, "!MIN_TERM");
            subscription.renewAt = timestamp;
            subscription.cancelAt = timestamp;
            subscriptionManager.renewSubscription(_subscriptionId); // force manager to process cancel
        } else {
            require(subscription.minTermAt == 0 || _cancelAt >= subscription.minTermAt, "!MIN_TERM");
            subscription.cancelAt = _cancelAt;

            emit SubscriptionPendingCancel(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
                subscription.ref, subscription.planId, _cancelAt);
        }
    }

    function managerCommand(
        uint256 _subscriptionId,
        ManagerCommand _command
    ) external override onlyManager whenNotPaused {

        Subscription storage subscription = subscriptions[_subscriptionId];

        uint32 timestamp = uint32(block.timestamp);

        if (_command == ManagerCommand.PlanChange) {
            bytes32 pendingPlanData = pendingPlanChanges[_subscriptionId];
            require(pendingPlanData > 0, "!INVALID(pendingPlanData)");

            PlanInfo memory newPlanInfo = _parsePlanData(pendingPlanData);

            emit SubscriptionChangedPlan(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
                subscription.ref, subscription.planId, newPlanInfo.planId, subscription.discountId);

            subscription.planId = newPlanInfo.planId;
            subscription.planData = pendingPlanData;

            if (newPlanInfo.minPeriods > 0) {
                subscription.minTermAt = timestamp + (newPlanInfo.period * newPlanInfo.minPeriods);
            }

            delete pendingPlanChanges[_subscriptionId]; // free up memory

        } else if (_command == ManagerCommand.Cancel) {
            subscription.status = SubscriptionStatus.Canceled;

            providerActiveSubscriptionCount[subscription.provider] -= 1;
            planActiveSubscriptionCount[subscription.provider][subscription.planId] -= 1;
            if (consumerProviderPlanActiveCount[ownerOf(_subscriptionId)][subscription.provider][subscription.planId] > 0) {
                consumerProviderPlanActiveCount[ownerOf(_subscriptionId)][subscription.provider][subscription.planId] -= 1;
            }

            emit SubscriptionCanceled(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
                subscription.ref, subscription.planId);

            _burn(_subscriptionId);

        } else if (_command == ManagerCommand.Pause) {
            subscription.status = SubscriptionStatus.Paused;

            providerActiveSubscriptionCount[subscription.provider] -= 1;
            planActiveSubscriptionCount[subscription.provider][subscription.planId] -= 1;
            if (consumerProviderPlanActiveCount[ownerOf(_subscriptionId)][subscription.provider][subscription.planId] > 0) {
                consumerProviderPlanActiveCount[ownerOf(_subscriptionId)][subscription.provider][subscription.planId] -= 1;
            }

            emit SubscriptionPaused(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
                subscription.ref, subscription.planId);

        } else if (_command == ManagerCommand.PastDue) {
            subscription.status = SubscriptionStatus.PastDue;

            emit SubscriptionPastDue(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
                subscription.ref, subscription.planId);

        } else if (_command == ManagerCommand.Renew) {
            PlanInfo memory planInfo = _parsePlanData(subscription.planData);

            if (subscription.status == SubscriptionStatus.Trialing) {
                emit SubscriptionTrialEnded(ownerOf(_subscriptionId), subscription.provider,
                    _subscriptionId, subscription.ref, subscription.planId);
            }

            subscription.renewAt = subscription.renewAt + planInfo.period;

            if (subscription.renewAt > timestamp) {
                // leave in current status unless subscription is current
                subscription.status = SubscriptionStatus.Active;
            }

            emit SubscriptionRenewed(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
                subscription.ref, subscription.planId);

        } else if (_command == ManagerCommand.ClearDiscount) {
                    subscription.discountId = 0;
                    subscription.discountData = 0;
        }

    }

    function getSubscription(
        uint256 _subscriptionId
    ) external override view returns (Subscription memory subscription, address currentOwner) {
        subscription = subscriptions[_subscriptionId];
        if (_exists(_subscriptionId)) {
            currentOwner = ownerOf(_subscriptionId);
        } else {
            currentOwner = address(0);
        }
    }

    function getConsumerSubscription(
        address _consumer,
        uint256 _idx
    ) external override view returns(uint256) {
        return consumerSubscriptions[_consumer][_idx];
    }

    function getActiveSubscriptionCount(
        address _consumer,
        address _provider,
        uint32 _planId
    ) external override view returns(uint256) {
        return consumerProviderPlanActiveCount[_consumer][_provider][_planId];
    }

    function getConsumerSubscriptionCount(
        address _consumer
    ) external override view returns (uint256) {
        return consumerSubscriptions[_consumer].length;
    }

    function getProviderSubscription(
        address _provider,
        uint256 _idx
    ) external override view returns(uint256) {
        return providerSubscriptions[_provider][_idx];
    }

    function getProviderSubscriptionCount(
        address _provider,
        bool _includeCanceled,
        uint32 _planId
    ) external override view returns (uint256) {
        if (_includeCanceled) {
            return providerSubscriptions[_provider].length;
        } else {
            if (_planId > 0) {
                return planActiveSubscriptionCount[_provider][_planId];
            } else {
                return providerActiveSubscriptionCount[_provider];
            }
        }
    }

    function getPendingPlanChange(
        uint256 _subscriptionId
    ) external override view returns (bytes32) {
        return pendingPlanChanges[_subscriptionId];
    }

    function _createSubscription(
        uint256 _nonce,
        bytes32[] calldata _planProof,  // [provider, ref, planData, merkleRoot, merkleProof...]
        bytes32[] calldata _discountProof, // [discountCodeProof, discountData, merkleRoot, merkleProof...]
        uint32 _cancelAt,
        bytes memory _providerSignature,
        string calldata _cid
    ) internal returns(uint256) {
        require(_planProof.length >= 4, "!INVALID(planProofLen)");

        // confirms merkleroots are in fact the ones provider committed to
        address provider;
        if (_discountProof.length >= 3) {
            provider = _verifyMerkleRoots(_planProof[0], _nonce, _planProof[3], _discountProof[2], _providerSignature);
        } else {
            provider = _verifyMerkleRoots(_planProof[0], _nonce, _planProof[3], 0, _providerSignature);
        }

        // confirms plan data is included in merkle root
        require(_verifyPlanProof(_planProof), "!INVALID(planProof)");

        // decode planData bytes32 into PlanInfo
        PlanInfo memory planInfo = _parsePlanData(_planProof[2]);

        // generate subscriptionId from plan info and ref
        uint256 subscriptionId = _generateSubscriptionId(_planProof[0], _planProof[1], _planProof[2]);

        require(planInfo.maxActive == 0 ||
            planActiveSubscriptionCount[provider][planInfo.planId] < planInfo.maxActive, "!MAX_ACTIVE");
        require(subscriptionPlans.getPlanStatus(provider, planInfo.planId) ==
            ICaskSubscriptionPlans.PlanStatus.Enabled, "!NOT_ENABLED");

        _safeMint(_msgSender(), subscriptionId);

        Subscription storage subscription = subscriptions[subscriptionId];

        uint32 timestamp = uint32(block.timestamp);

        subscription.provider = provider;
        subscription.planId = planInfo.planId;
        subscription.ref = _planProof[1];
        subscription.planData = _planProof[2];
        subscription.cancelAt = _cancelAt;
        subscription.cid = _cid;
        subscription.createdAt = timestamp;

        if (planInfo.minPeriods > 0) {
            subscription.minTermAt = timestamp + (planInfo.period * planInfo.minPeriods);
        }

        if (planInfo.price == 0) {
            // free plan, never renew to save gas
            subscription.status = SubscriptionStatus.Active;
            subscription.renewAt = 0;
        } else if (planInfo.freeTrial > 0) {
            // if trial period, charge will happen after trial is over
            subscription.status = SubscriptionStatus.Trialing;
            subscription.renewAt = timestamp + planInfo.freeTrial;
        } else {
            // if no trial period, charge now
            subscription.status = SubscriptionStatus.Active;
            subscription.renewAt = timestamp;
        }

        consumerSubscriptions[_msgSender()].push(subscriptionId);
        providerSubscriptions[provider].push(subscriptionId);
        providerActiveSubscriptionCount[provider] += 1;
        planActiveSubscriptionCount[provider][planInfo.planId] += 1;
        consumerProviderPlanActiveCount[_msgSender()][provider][planInfo.planId] += 1;

        (
        subscription.discountId,
        subscription.discountData
        ) = _verifyDiscountProof(ownerOf(subscriptionId), subscription.provider, planInfo.planId, _discountProof);

        subscriptionManager.renewSubscription(subscriptionId); // registers subscription with manager

        require(subscription.status == SubscriptionStatus.Active ||
                subscription.status == SubscriptionStatus.Trialing, "!UNPROCESSABLE");

        emit SubscriptionCreated(ownerOf(subscriptionId), subscription.provider, subscriptionId,
            subscription.ref, subscription.planId, subscription.discountId);

        return subscriptionId;
    }

    function _changeSubscriptionPlan(
        uint256 _subscriptionId,
        uint256 _nonce,
        bytes32[] calldata _planProof,  // [provider, ref, planData, merkleRoot, merkleProof...]
        bytes32[] calldata _discountProof, // [discountCodeProof, discountData, merkleRoot, merkleProof...]
        bytes memory _providerSignature,
        string calldata _cid
    ) internal {
        require(_planProof.length >= 4, "!INVALID(planProof)");

        Subscription storage subscription = subscriptions[_subscriptionId];

        require(subscription.renewAt == 0 || subscription.renewAt > uint32(block.timestamp), "!NEED_RENEWAL");
        require(subscription.status == SubscriptionStatus.Active ||
            subscription.status == SubscriptionStatus.Trialing, "!INVALID(status)");

        // confirms merkleroots are in fact the ones provider committed to
        address provider;
        if (_discountProof.length >= 3) {
            provider = _verifyMerkleRoots(_planProof[0], _nonce, _planProof[3], _discountProof[2], _providerSignature);
        } else {
            provider = _verifyMerkleRoots(_planProof[0], _nonce, _planProof[3], 0, _providerSignature);
        }

        // confirms plan data is included in merkle root
        require(_verifyPlanProof(_planProof), "!INVALID(planProof)");

        // decode planData bytes32 into PlanInfo
        PlanInfo memory newPlanInfo = _parsePlanData(_planProof[2]);

        require(subscription.provider == provider, "!INVALID(provider)");

        subscription.cid = _cid;

        if (subscription.discountId == 0 && _discountProof.length >= 3 && _discountProof[0] > 0) {
            (
            subscription.discountId,
            subscription.discountData
            ) = _verifyDiscountProof(ownerOf(_subscriptionId), subscription.provider,
                newPlanInfo.planId, _discountProof);
        }

        if (subscription.planId != newPlanInfo.planId) {
            require(subscriptionPlans.getPlanStatus(provider, newPlanInfo.planId) ==
                ICaskSubscriptionPlans.PlanStatus.Enabled, "!NOT_ENABLED");
            _performPlanChange(_subscriptionId, newPlanInfo, _planProof[2]);
        }
    }

    function _performPlanChange(
        uint256 _subscriptionId,
        PlanInfo memory _newPlanInfo,
        bytes32 _planData
    ) internal {
        Subscription storage subscription = subscriptions[_subscriptionId];

        PlanInfo memory currentPlanInfo = _parsePlanData(subscription.planData);

        if (subscription.status == SubscriptionStatus.Trialing) { // still in trial, just change now

            // adjust renewal based on new plan trial length
            subscription.renewAt = subscription.renewAt - currentPlanInfo.freeTrial + _newPlanInfo.freeTrial;

            // if new plan trial length would have caused trial to already be over, end trial as of now
            // subscription will be charged and converted to active during next keeper run
            if (subscription.renewAt <= uint32(block.timestamp)) {
                subscription.renewAt = uint32(block.timestamp);
            }

            _swapPlan(_subscriptionId, _newPlanInfo, _planData);

        } else if (_newPlanInfo.price / _newPlanInfo.period ==
            currentPlanInfo.price / currentPlanInfo.period)
        { // straight swap

            _swapPlan(_subscriptionId, _newPlanInfo, _planData);

        } else if (_newPlanInfo.price / _newPlanInfo.period >
            currentPlanInfo.price / currentPlanInfo.period)
        { // upgrade

            _upgradePlan(_subscriptionId, currentPlanInfo, _newPlanInfo, _planData);

        } else { // downgrade - to take affect at next renewal

            _scheduleSwapPlan(_subscriptionId, _newPlanInfo.planId, _planData);
        }
    }

    function _verifyDiscountProof(
        address _consumer,
        address _provider,
        uint32 _planId,
        bytes32[] calldata _discountProof // [discountValidator, discountData, merkleRoot, merkleProof...]
    ) internal returns(bytes32, bytes32) {
        if (_discountProof[0] > 0) {
            bytes32 discountId = subscriptionPlans.verifyAndConsumeDiscount(_consumer, _provider,
                _planId, _discountProof);
            if (discountId > 0)
            {
                return (discountId, _discountProof[1]);
            }
        }
        return (0,0);
    }

    function _verifyPlanProof(
        bytes32[] calldata _planProof // [provider, ref, planData, merkleRoot, merkleProof...]
    ) internal view returns(bool) {
        return subscriptionPlans.verifyPlan(_planProof[2], _planProof[3], _planProof[4:]);
    }

    function _generateSubscriptionId(
        bytes32 _providerAddr,
        bytes32 _ref,
        bytes32 _planData
    ) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_msgSender(), _providerAddr,
            _planData, _ref, block.number, block.timestamp)));
    }

    function _parsePlanData(
        bytes32 _planData
    ) internal pure returns(PlanInfo memory) {
        bytes1 options = bytes1(_planData << 248);
        return PlanInfo({
            price: uint256(_planData >> 160),
            planId: uint32(bytes4(_planData << 96)),
            period: uint32(bytes4(_planData << 128)),
            freeTrial: uint32(bytes4(_planData << 160)),
            maxActive: uint32(bytes4(_planData << 192)),
            minPeriods: uint16(bytes2(_planData << 224)),
            gracePeriod: uint8(bytes1(_planData << 240)),
            canPause: options & 0x01 == 0x01,
            canTransfer: options & 0x02 == 0x02
        });
    }

    function _parseNetworkData(
        bytes32 _networkData
    ) internal pure returns(NetworkInfo memory) {
        return NetworkInfo({
            network: address(bytes20(_networkData)),
            feeBps: uint16(bytes2(_networkData << 160))
        });
    }

    function _scheduleSwapPlan(
        uint256 _subscriptionId,
        uint32 newPlanId,
        bytes32 _newPlanData
    ) internal {
        Subscription storage subscription = subscriptions[_subscriptionId];

        pendingPlanChanges[_subscriptionId] = _newPlanData;

        emit SubscriptionPendingChangePlan(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
            subscription.ref, subscription.planId, newPlanId);
    }

    function _swapPlan(
        uint256 _subscriptionId,
        PlanInfo memory _newPlanInfo,
        bytes32 _newPlanData
    ) internal {
        Subscription storage subscription = subscriptions[_subscriptionId];

        emit SubscriptionChangedPlan(ownerOf(_subscriptionId), subscription.provider, _subscriptionId,
            subscription.ref, subscription.planId, _newPlanInfo.planId, subscription.discountId);

        if (_newPlanInfo.minPeriods > 0) {
            subscription.minTermAt = uint32(block.timestamp + (_newPlanInfo.period * _newPlanInfo.minPeriods));
        }

        subscription.planId = _newPlanInfo.planId;
        subscription.planData = _newPlanData;
    }

    function _upgradePlan(
        uint256 _subscriptionId,
        PlanInfo memory _currentPlanInfo,
        PlanInfo memory _newPlanInfo,
        bytes32 _newPlanData
    ) internal {
        Subscription storage subscription = subscriptions[_subscriptionId];

        _swapPlan(_subscriptionId, _newPlanInfo, _newPlanData);

        if (_currentPlanInfo.price == 0 && _newPlanInfo.price != 0) {
            // coming from free plan, no prorate
            subscription.renewAt = uint32(block.timestamp);
            subscriptionManager.renewSubscription(_subscriptionId); // register paid plan with manager
            require(subscription.status == SubscriptionStatus.Active, "!UNPROCESSABLE"); // make sure payment processed
        } else {
            // prorated payment now - next renewal will charge new price
            uint256 newAmount = ((_newPlanInfo.price / _newPlanInfo.period) -
                (_currentPlanInfo.price / _currentPlanInfo.period)) *
                (subscription.renewAt - uint32(block.timestamp));
            require(subscriptionManager.processSinglePayment(ownerOf(_subscriptionId), subscription.provider,
                _subscriptionId, newAmount), "!UNPROCESSABLE");
        }

    }


    /************************** ADMIN FUNCTIONS **************************/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setManager(
        address _subscriptionManager
    ) external onlyOwner {
        subscriptionManager = ICaskSubscriptionManager(_subscriptionManager);
    }

    function setTrustedForwarder(
        address _forwarder
    ) external onlyOwner {
        _setTrustedForwarder(_forwarder);
    }

    function _verifyMerkleRoots(
        bytes32 providerAddr,
        uint256 _nonce,
        bytes32 _planMerkleRoot,
        bytes32 _discountMerkleRoot,
        bytes memory _providerSignature
    ) internal view returns (address) {
        address provider = address(bytes20(providerAddr << 96));
        require(subscriptionPlans.verifyProviderSignature(
                provider,
                _nonce,
                _planMerkleRoot,
                _discountMerkleRoot,
                _providerSignature
        ), "!INVALID(signature)");
        return provider;
    }

    function _verifyNetworkData(
        bytes32 _networkData,
        bytes memory _networkSignature
    ) internal view returns (address) {
        NetworkInfo memory networkInfo = _parseNetworkData(_networkData);
        require(subscriptionPlans.verifyNetworkData(networkInfo.network, _networkData, _networkSignature),
            "!INVALID(networkSignature)");
        return networkInfo.network;
    }

}