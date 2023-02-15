// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/INodeOperatorRegistry.sol";
import "./interfaces/IValidatorFactory.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/IStMATIC.sol";

/// @title NodeOperatorRegistry
/// @author 2021 ShardLabs.
/// @notice NodeOperatorRegistry is the main contract that manage validators
/// @dev NodeOperatorRegistry is the main contract that manage operators.
contract NodeOperatorRegistry is
    INodeOperatorRegistry,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    enum NodeOperatorStatus {
        INACTIVE,
        ACTIVE,
        STOPPED,
        UNSTAKED,
        CLAIMED,
        EXIT,
        JAILED,
        EJECTED
    }
    /// @notice The node operator struct
    /// @param status node operator status(INACTIVE, ACTIVE, STOPPED, CLAIMED, UNSTAKED, EXIT, JAILED, EJECTED).
    /// @param name node operator name.
    /// @param rewardAddress Validator public key used for access control and receive rewards.
    /// @param validatorId validator id of this node operator on the polygon stake manager.
    /// @param signerPubkey public key used on heimdall.
    /// @param validatorShare validator share contract used to delegate for on polygon.
    /// @param validatorProxy the validator proxy, the owner of the validator.
    /// @param commissionRate the commission rate applied by the operator on polygon.
    /// @param maxDelegateLimit max delegation limit that StMatic contract will delegate to this operator each time delegate function is called.
    struct NodeOperator {
        NodeOperatorStatus status;
        string name;
        address rewardAddress;
        bytes signerPubkey;
        address validatorShare;
        address validatorProxy;
        uint256 validatorId;
        uint256 commissionRate;
        uint256 maxDelegateLimit;
    }

    /// @notice all the roles.
    bytes32 public constant REMOVE_OPERATOR_ROLE =
        keccak256("LIDO_REMOVE_OPERATOR");
    bytes32 public constant PAUSE_OPERATOR_ROLE =
        keccak256("LIDO_PAUSE_OPERATOR");
    bytes32 public constant DAO_ROLE = keccak256("LIDO_DAO");

    /// @notice contract version.
    string public version;
    /// @notice total node operators.
    uint256 private totalNodeOperators;

    /// @notice validatorFactory address.
    address private validatorFactory;
    /// @notice stakeManager address.
    address private stakeManager;
    /// @notice polygonERC20 token (Matic) address.
    address private polygonERC20;
    /// @notice stMATIC address.
    address private stMATIC;

    /// @notice keeps track of total number of operators
    uint256 nodeOperatorCounter;

    /// @notice min amount allowed to stake per validator.
    uint256 public minAmountStake;

    /// @notice min HeimdallFees allowed to stake per validator.
    uint256 public minHeimdallFees;

    /// @notice commision rate applied to all the operators.
    uint256 public commissionRate;

    /// @notice allows restake.
    bool public allowsRestake;

    /// @notice default max delgation limit.
    uint256 public defaultMaxDelegateLimit;

    /// @notice This stores the operators ids.
    uint256[] private operatorIds;

    /// @notice Mapping of all owners with node operator id. Mapping is used to be able to
    /// extend the struct.
    mapping(address => uint256) private operatorOwners;


    /// @notice Mapping of all node operators. Mapping is used to be able to extend the struct.
    mapping(uint256 => NodeOperator) private operators;

    /// --------------------------- Modifiers-----------------------------------

    /// @notice Check if the msg.sender has permission.
    /// @param _role role needed to call function.
    modifier userHasRole(bytes32 _role) {
        checkCondition(hasRole(_role, msg.sender), "unauthorized");
        _;
    }

    /// @notice Check if the amount is inbound.
    /// @param _amount amount to stake.
    modifier checkStakeAmount(uint256 _amount) {
        checkCondition(_amount >= minAmountStake, "Invalid amount");
        _;
    }

    /// @notice Check if the heimdall fee is inbound.
    /// @param _heimdallFee heimdall fee.
    modifier checkHeimdallFees(uint256 _heimdallFee) {
        checkCondition(_heimdallFee >= minHeimdallFees, "Invalid fees");
        _;
    }

    /// @notice Check if the maxDelegateLimit is less or equal to 10 Billion.
    /// @param _maxDelegateLimit max delegate limit.
    modifier checkMaxDelegationLimit(uint256 _maxDelegateLimit) {
        checkCondition(
            _maxDelegateLimit <= 10000000000 ether,
            "Max amount <= 10B"
        );
        _;
    }

    /// @notice Check if the rewardAddress is already used.
    /// @param _rewardAddress new reward address.
    modifier checkIfRewardAddressIsUsed(address _rewardAddress) {
        checkCondition(
            operatorOwners[_rewardAddress] == 0 && _rewardAddress != address(0),
            "Address used"
        );
        _;
    }

    /// -------------------------- initialize ----------------------------------

    /// @notice Initialize the NodeOperator contract.
    function initialize(
        address _validatorFactory,
        address _stakeManager,
        address _polygonERC20,
        address _stMATIC
    ) external initializer {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        validatorFactory = _validatorFactory;
        stakeManager = _stakeManager;
        polygonERC20 = _polygonERC20;
        stMATIC = _stMATIC;

        minAmountStake = 10 * 10**18;
        minHeimdallFees = 20 * 10**18;
        defaultMaxDelegateLimit = 10 ether;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REMOVE_OPERATOR_ROLE, msg.sender);
        _setupRole(PAUSE_OPERATOR_ROLE, msg.sender);
        _setupRole(DAO_ROLE, msg.sender);
    }

    /// ----------------------------- API --------------------------------------

    /// @notice Add a new node operator to the system.
    /// @dev The operator life cycle starts when we call the addOperator
    /// func allows adding a new operator. During this call, a new validatorProxy is
    /// deployed by the ValidatorFactory which we can use later to interact with the
    /// Polygon StakeManager. At the end of this call, the status of the operator
    /// will be INACTIVE.
    /// @param _name the node operator name.
    /// @param _rewardAddress address used for ACL and receive rewards.
    /// @param _signerPubkey public key used on heimdall len 64 bytes.
    function addOperator(
        string memory _name,
        address _rewardAddress,
        bytes memory _signerPubkey
    )
        external
        override
        whenNotPaused
        userHasRole(DAO_ROLE)
        checkIfRewardAddressIsUsed(_rewardAddress)
    {
        nodeOperatorCounter++;
        address validatorProxy = IValidatorFactory(validatorFactory).create();

        operators[nodeOperatorCounter] = NodeOperator({
            status: NodeOperatorStatus.INACTIVE,
            name: _name,
            rewardAddress: _rewardAddress,
            validatorId: 0,
            signerPubkey: _signerPubkey,
            validatorShare: address(0),
            validatorProxy: validatorProxy,
            commissionRate: commissionRate,
            maxDelegateLimit: defaultMaxDelegateLimit
        });
        operatorIds.push(nodeOperatorCounter);
        totalNodeOperators++;
        operatorOwners[_rewardAddress] = nodeOperatorCounter;

        emit AddOperator(nodeOperatorCounter);
    }

    /// @notice Allows to stop an operator from the system.
    /// @param _operatorId the node operator id.
    function stopOperator(uint256 _operatorId)
        external
        override
    {

        (, NodeOperator storage no) = getOperator(_operatorId);
        require(
            no.rewardAddress == msg.sender || hasRole(DAO_ROLE, msg.sender), "unauthorized"
        );
        NodeOperatorStatus status = getOperatorStatus(no);
        checkCondition(
            status == NodeOperatorStatus.ACTIVE || status == NodeOperatorStatus.INACTIVE ||
            status == NodeOperatorStatus.JAILED
        , "Invalid status");

        if (status == NodeOperatorStatus.INACTIVE) {
            no.status = NodeOperatorStatus.EXIT;
        } else {
            // IStMATIC(stMATIC).withdrawTotalDelegated(no.validatorShare);
            no.status = NodeOperatorStatus.STOPPED;
        }
        emit StopOperator(_operatorId);
    }

    /// @notice Allows to remove an operator from the system.when the operator status is
    /// set to EXIT the GOVERNANCE can call the removeOperator func to delete the operator,
    /// and the validatorProxy used to interact with the Polygon stakeManager.
    /// @param _operatorId the node operator id.
    function removeOperator(uint256 _operatorId)
        external
        override
        whenNotPaused
        userHasRole(REMOVE_OPERATOR_ROLE)
    {
        (, NodeOperator storage no) = getOperator(_operatorId);
        checkCondition(no.status == NodeOperatorStatus.EXIT, "Invalid status");

        // update the operatorIds array by removing the operator id.
        for (uint256 idx = 0; idx < operatorIds.length - 1; idx++) {
            if (_operatorId == operatorIds[idx]) {
                operatorIds[idx] = operatorIds[operatorIds.length - 1];
                break;
            }
        }
        operatorIds.pop();

        totalNodeOperators--;
        IValidatorFactory(validatorFactory).remove(no.validatorProxy);
        delete operatorOwners[no.rewardAddress];
        delete operators[_operatorId];

        emit RemoveOperator(_operatorId);
    }

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the PoLido protocol.
    function joinOperator() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            getOperatorStatus(no) == NodeOperatorStatus.INACTIVE,
            "Invalid status"
        );

        IStakeManager sm = IStakeManager(stakeManager);
        uint256 validatorId = sm.getValidatorId(msg.sender);

        checkCondition(validatorId != 0, "ValidatorId=0");

        IStakeManager.Validator memory poValidator = sm.validators(validatorId);

        checkCondition(
            poValidator.contractAddress != address(0),
            "Validator has no ValidatorShare"
        );

        checkCondition(
            (poValidator.status == IStakeManager.Status.Active
                ) && poValidator.deactivationEpoch == 0 ,
            "Validator isn't ACTIVE"
        );

        checkCondition(
            poValidator.signer ==
                address(uint160(uint256(keccak256(no.signerPubkey)))),
            "Invalid Signer"
        );

        IValidator(no.validatorProxy).join(
            validatorId,
            sm.NFTContract(),
            msg.sender,
            no.commissionRate,
            stakeManager
        );

        no.validatorId = validatorId;

        address validatorShare = sm.getValidatorContract(validatorId);
        no.validatorShare = validatorShare;

        emit JoinOperator(operatorId);
    }

    /// ------------------------Stake Manager API-------------------------------

    /// @notice Allows to stake a validator on the Polygon stakeManager contract.
    /// @dev The stake func allows each operator's owner to stake, but before that,
    /// the owner has to approve the amount + Heimdall fees to the ValidatorProxy.
    /// At the end of this call, the status of the operator is set to ACTIVE.
    /// @param _amount amount to stake.
    /// @param _heimdallFee heimdall fees.
    function stake(uint256 _amount, uint256 _heimdallFee)
        external
        override
        whenNotPaused
        checkStakeAmount(_amount)
        checkHeimdallFees(_heimdallFee)
    {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            getOperatorStatus(no) == NodeOperatorStatus.INACTIVE,
            "Invalid status"
        );

        (uint256 validatorId, address validatorShare) = IValidator(
            no.validatorProxy
        ).stake(
                msg.sender,
                _amount,
                _heimdallFee,
                true,
                no.signerPubkey,
                no.commissionRate,
                stakeManager,
                polygonERC20
            );

        no.validatorId = validatorId;
        no.validatorShare = validatorShare;

        emit StakeOperator(operatorId, _amount, _heimdallFee);
    }

    /// @notice Allows to restake Matics to Polygon stakeManager
    /// @dev restake allows an operator's owner to increase the total staked amount
    /// on Polygon. The owner has to approve the amount to the ValidatorProxy then make
    /// a call.
    /// @param _amount amount to stake.
    function restake(uint256 _amount, bool _restakeRewards)
        external
        override
        whenNotPaused
    {
        checkCondition(allowsRestake, "Restake is disabled");
        if (_amount == 0) {
            revert("Amount is ZERO");
        }

        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            getOperatorStatus(no) == NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );
        IValidator(no.validatorProxy).restake(
            msg.sender,
            no.validatorId,
            _amount,
            _restakeRewards,
            stakeManager,
            polygonERC20
        );

        emit RestakeOperator(operatorId, _amount, _restakeRewards);
    }

    /// @notice Unstake a validator from the Polygon stakeManager contract.
    /// @dev when the operators's owner wants to quite the PoLido protocol he can call
    /// the unstake func, in this case, the operator status is set to UNSTAKED.
    function unstake() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        NodeOperatorStatus status = getOperatorStatus(no);
        checkCondition(
            status == NodeOperatorStatus.ACTIVE ||
            status == NodeOperatorStatus.JAILED ||
            status == NodeOperatorStatus.EJECTED,
            "Invalid status"
        );
        if (status == NodeOperatorStatus.ACTIVE) {
            IValidator(no.validatorProxy).unstake(no.validatorId, stakeManager);
        }
        _unstake(operatorId, no);
    }

    /// @notice The DAO unstake the operator if it was unstaked by the stakeManager.
    /// @dev when the operator was unstaked by the stage Manager the DAO can use this
    /// function to update the operator status and also withdraw the delegated tokens,
    /// without waiting for the owner to call the unstake function
    /// @param _operatorId operator id.
    function unstake(uint256 _operatorId) external userHasRole(DAO_ROLE) {
        NodeOperator storage no = operators[_operatorId];
        NodeOperatorStatus status = getOperatorStatus(no);
        checkCondition(status == NodeOperatorStatus.EJECTED, "Invalid status");
        _unstake(_operatorId, no);
    }

    function _unstake(uint256 _operatorId, NodeOperator storage no)
        private
        whenNotPaused
    {
        IStMATIC(stMATIC).withdrawTotalDelegated(no.validatorShare);
        no.status = NodeOperatorStatus.UNSTAKED;

        emit UnstakeOperator(_operatorId);
    }

    /// @notice Allows the operator's owner to migrate the validator ownership to rewardAddress.
    /// This can be done only in the case where this operator was stopped by the DAO.
    function migrate() external override nonReentrant {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(no.status == NodeOperatorStatus.STOPPED, "Invalid status");
        IValidator(no.validatorProxy).migrate(
            no.validatorId,
            IStakeManager(stakeManager).NFTContract(),
            no.rewardAddress
        );

        no.status = NodeOperatorStatus.EXIT;
        emit MigrateOperator(operatorId);
    }

    /// @notice Allows to unjail the validator and turn his status from UNSTAKED to ACTIVE.
    /// @dev when an operator is JAILED the owner can switch back and stake the
    /// operator by calling the unjail func, in this case, the operator status is set
    /// to back ACTIVE.
    function unjail() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);

        checkCondition(
            getOperatorStatus(no) == NodeOperatorStatus.JAILED,
            "Invalid status"
        );

        IValidator(no.validatorProxy).unjail(no.validatorId, stakeManager);

        emit Unjail(operatorId);
    }

    /// @notice Allows to top up heimdall fees.
    /// @dev the operator's owner can topUp the heimdall fees by calling the
    /// topUpForFee, but before that node operator needs to approve the amount of heimdall
    /// fees to his validatorProxy.
    /// @param _heimdallFee amount
    function topUpForFee(uint256 _heimdallFee)
        external
        override
        whenNotPaused
        checkHeimdallFees(_heimdallFee)
    {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            getOperatorStatus(no) == NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );
        IValidator(no.validatorProxy).topUpForFee(
            msg.sender,
            _heimdallFee,
            stakeManager,
            polygonERC20
        );

        emit TopUpHeimdallFees(operatorId, _heimdallFee);
    }

    /// @notice Allows to unstake staked tokens after withdraw delay.
    /// @dev after the unstake the operator and waiting for the Polygon withdraw_delay
    /// the owner can transfer back his staked balance by calling
    /// unsttakeClaim, after that the operator status is set to CLAIMED
    function unstakeClaim() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            getOperatorStatus(no) == NodeOperatorStatus.UNSTAKED,
            "Invalid status"
        );
        uint256 amount = IValidator(no.validatorProxy).unstakeClaim(
            no.validatorId,
            msg.sender,
            stakeManager,
            polygonERC20
        );

        no.status = NodeOperatorStatus.CLAIMED;
        emit UnstakeClaim(operatorId, amount);
    }

    /// @notice Allows withdraw heimdall fees
    /// @dev the operator's owner can claim the heimdall fees.
    /// func, after that the operator status is set to EXIT.
    /// @param _accumFeeAmount accumulated heimdall fees
    /// @param _index index
    /// @param _proof proof
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof
    ) external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.CLAIMED,
            "Invalid status"
        );
        IValidator(no.validatorProxy).claimFee(
            _accumFeeAmount,
            _index,
            _proof,
            no.rewardAddress,
            stakeManager,
            polygonERC20
        );

        no.status = NodeOperatorStatus.EXIT;
        emit ClaimFee(operatorId);
    }

    /// @notice Allows the operator's owner to withdraw rewards.
    function withdrawRewards() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);

        address rewardAddress = no.rewardAddress;
        uint256 rewards = IValidator(no.validatorProxy).withdrawRewards(
            no.validatorId,
            rewardAddress,
            stakeManager,
            polygonERC20
        );

        emit WithdrawRewards(operatorId, rewardAddress, rewards);
    }

    /// @notice Allows the operator's owner to update signer publickey.
    /// @param _signerPubkey new signer publickey
    function updateSigner(bytes memory _signerPubkey)
        external
        override
        whenNotPaused
    {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        NodeOperatorStatus status = getOperatorStatus(no);
        checkCondition(
            status == NodeOperatorStatus.ACTIVE || status == NodeOperatorStatus.INACTIVE,
            "Invalid status"
        );
        if (status == NodeOperatorStatus.ACTIVE) {
            IValidator(no.validatorProxy).updateSigner(
                no.validatorId,
                _signerPubkey,
                stakeManager
            );
        }

        no.signerPubkey = _signerPubkey;

        emit UpdateSignerPubkey(operatorId);
    }

    /// @notice Allows the operator owner to update the name.
    /// @param _name new operator name.
    function setOperatorName(string memory _name)
        external
        override
        whenNotPaused
    {
        // uint256 operatorId = getOperatorId(msg.sender);
        // NodeOperator storage no = operators[operatorId];
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        NodeOperatorStatus status = getOperatorStatus(no);

        checkCondition(
            status == NodeOperatorStatus.ACTIVE || status == NodeOperatorStatus.INACTIVE,
            "Invalid status"
        );
        no.name = _name;

        emit NewName(operatorId, _name);
    }

    /// @notice Allows the operator owner to update the rewardAddress.
    /// @param _rewardAddress new reward address.
    function setOperatorRewardAddress(address _rewardAddress)
        external
        override
        whenNotPaused
        checkIfRewardAddressIsUsed(_rewardAddress)
    {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        no.rewardAddress = _rewardAddress;

        operatorOwners[_rewardAddress] = operatorId;
        delete operatorOwners[msg.sender];

        emit NewRewardAddress(operatorId, _rewardAddress);
    }

    /// -------------------------------DAO--------------------------------------

    /// @notice Allows the DAO to set the operator defaultMaxDelegateLimit.
    /// @param _defaultMaxDelegateLimit default max delegation amount.
    function setDefaultMaxDelegateLimit(uint256 _defaultMaxDelegateLimit)
        external
        override
        userHasRole(DAO_ROLE)
        checkMaxDelegationLimit(_defaultMaxDelegateLimit)
    {
        defaultMaxDelegateLimit = _defaultMaxDelegateLimit;
    }

    /// @notice Allows the DAO to set the operator maxDelegateLimit.
    /// @param _operatorId operator id.
    /// @param _maxDelegateLimit max amount to delegate .
    function setMaxDelegateLimit(uint256 _operatorId, uint256 _maxDelegateLimit)
        external
        override
        userHasRole(DAO_ROLE)
        checkMaxDelegationLimit(_maxDelegateLimit)
    {
        (, NodeOperator storage no) = getOperator(_operatorId);
        no.maxDelegateLimit = _maxDelegateLimit;
    }

    /// @notice Allows to set the commission rate used.
    function setCommissionRate(uint256 _commissionRate)
        external
        override
        userHasRole(DAO_ROLE)
    {
        commissionRate = _commissionRate;
    }

    /// @notice Allows the dao to update commission rate for an operator.
    /// @param _operatorId id of the operator
    /// @param _newCommissionRate new commission rate
    function updateOperatorCommissionRate(
        uint256 _operatorId,
        uint256 _newCommissionRate
    ) external override userHasRole(DAO_ROLE) {
        (, NodeOperator storage no) = getOperator(_operatorId);
        NodeOperatorStatus status = getOperatorStatus(no);
        checkCondition(
            no.rewardAddress != address(0) ||
                status == NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );

        if (status == NodeOperatorStatus.ACTIVE) {
            IValidator(no.validatorProxy).updateCommissionRate(
                no.validatorId,
                _newCommissionRate,
                stakeManager
            );
        }

        no.commissionRate = _newCommissionRate;

        emit UpdateCommissionRate(_operatorId, _newCommissionRate);
    }

    /// @notice Allows to update the stake amount and heimdall fees
    /// @param _minAmountStake min amount to stake
    /// @param _minHeimdallFees min amount of heimdall fees
    function setStakeAmountAndFees(
        uint256 _minAmountStake,
        uint256 _minHeimdallFees
    )
        external
        override
        userHasRole(DAO_ROLE)
        checkStakeAmount(_minAmountStake)
        checkHeimdallFees(_minHeimdallFees)
    {
        minAmountStake = _minAmountStake;
        minHeimdallFees = _minHeimdallFees;
    }

    /// @notice Allows to pause the contract.
    function togglePause() external override userHasRole(PAUSE_OPERATOR_ROLE) {
        paused() ? _unpause() : _pause();
    }

    /// @notice Allows to toggle restake.
    function setRestake(bool _restake) external override userHasRole(DAO_ROLE) {
        allowsRestake = _restake;
    }

    /// @notice Allows to set the StMATIC contract address.
    function setStMATIC(address _stMATIC)
        external
        override
        userHasRole(DAO_ROLE)
    {
        stMATIC = _stMATIC;
    }

    /// @notice Allows to set the validator factory contract address.
    function setValidatorFactory(address _validatorFactory)
        external
        override
        userHasRole(DAO_ROLE)
    {
        validatorFactory = _validatorFactory;
    }

    /// @notice Allows to set the stake manager contract address.
    function setStakeManager(address _stakeManager)
        external
        override
        userHasRole(DAO_ROLE)
    {
        stakeManager = _stakeManager;
    }

    /// @notice Allows to set the contract version.
    /// @param _version contract version
    function setVersion(string memory _version)
        external
        override
        userHasRole(DEFAULT_ADMIN_ROLE)
    {
        version = _version;
    }

    /// @notice Allows to get a node operator by msg.sender.
    /// @param _owner a valid address of an operator owner, if not set msg.sender will be used.
    /// @return op returns a node operator.
    function getNodeOperator(address _owner)
        external
        view
        returns (NodeOperator memory)
    {
        uint256 operatorId = operatorOwners[_owner];
        return _getNodeOperator(operatorId);
    }

    /// @notice Allows to get a node operator by _operatorId.
    /// @param _operatorId the id of the operator.
    /// @return op returns a node operator.
    function getNodeOperator(uint256 _operatorId)
        external
        view
        returns (NodeOperator memory)
    {
        return _getNodeOperator(_operatorId);
    }

    function _getNodeOperator(uint256 _operatorId)
        private
        view
        returns (NodeOperator memory)
    {
        (, NodeOperator memory nodeOperator) = getOperator(_operatorId);
        nodeOperator.status = getOperatorStatus(nodeOperator);
        return nodeOperator;
    }

    function getOperatorStatus(NodeOperator memory _op)
        private
        view
        returns (NodeOperatorStatus res)
    {
        if (_op.status == NodeOperatorStatus.STOPPED) {
            res = NodeOperatorStatus.STOPPED;
        } else if (_op.status == NodeOperatorStatus.CLAIMED) {
            res = NodeOperatorStatus.CLAIMED;
        } else if (_op.status == NodeOperatorStatus.EXIT) {
            res = NodeOperatorStatus.EXIT;
        } else if (_op.status == NodeOperatorStatus.UNSTAKED) {
            res = NodeOperatorStatus.UNSTAKED;
        } else {
            IStakeManager.Validator memory v = IStakeManager(stakeManager)
                .validators(_op.validatorId);
            if (
                v.status == IStakeManager.Status.Active &&
                v.deactivationEpoch == 0
            ) {
                res = NodeOperatorStatus.ACTIVE;
            } else if (
                (
                    v.status == IStakeManager.Status.Active ||
                    v.status == IStakeManager.Status.Locked
                ) &&
                v.deactivationEpoch != 0
            ) {
                res = NodeOperatorStatus.EJECTED;
            } else if (
                v.status == IStakeManager.Status.Locked &&
                v.deactivationEpoch == 0
            ) {
                res = NodeOperatorStatus.JAILED;
            } else {
                res = NodeOperatorStatus.INACTIVE;
            }
        }
    }

    /// @notice Allows to get a validator share address.
    /// @param _operatorId the id of the operator.
    /// @return va returns a stake manager validator.
    function getValidatorShare(uint256 _operatorId)
        external
        view
        returns (address)
    {
        (, NodeOperator memory op) = getOperator(_operatorId);
        return op.validatorShare;
    }

    /// @notice Allows to get a validator from stake manager.
    /// @param _operatorId the id of the operator.
    /// @return va returns a stake manager validator.
    function getValidator(uint256 _operatorId)
        external
        view
        returns (IStakeManager.Validator memory va)
    {
        (, NodeOperator memory op) = getOperator(_operatorId);
        va = IStakeManager(stakeManager).validators(op.validatorId);
    }

    /// @notice Allows to get a validator from stake manager.
    /// @param _owner user address.
    /// @return va returns a stake manager validator.
    function getValidator(address _owner)
        external
        view
        returns (IStakeManager.Validator memory va)
    {
        (, NodeOperator memory op) = getOperator(operatorOwners[_owner]);
        va = IStakeManager(stakeManager).validators(op.validatorId);
    }

    /// @notice Get the stMATIC contract addresses
    function getContracts()
        external
        view
        override
        returns (
            address _validatorFactory,
            address _stakeManager,
            address _polygonERC20,
            address _stMATIC
        )
    {
        _validatorFactory = validatorFactory;
        _stakeManager = stakeManager;
        _polygonERC20 = polygonERC20;
        _stMATIC = stMATIC;
    }

    /// @notice Get the global state
    function getState()
        external
        view
        override
        returns (
            uint256 _totalNodeOperator,
            uint256 _totalInactiveNodeOperator,
            uint256 _totalActiveNodeOperator,
            uint256 _totalStoppedNodeOperator,
            uint256 _totalUnstakedNodeOperator,
            uint256 _totalClaimedNodeOperator,
            uint256 _totalExitNodeOperator,
            uint256 _totalJailedNodeOperator,
            uint256 _totalEjectedNodeOperator
        )
    {
        uint256 operatorIdsLength = operatorIds.length;
        _totalNodeOperator = operatorIdsLength;
        for (uint256 idx = 0; idx < operatorIdsLength; idx++) {
            uint256 operatorId = operatorIds[idx];
            NodeOperator memory op = operators[operatorId];
            NodeOperatorStatus status = getOperatorStatus(op);

            if (status == NodeOperatorStatus.INACTIVE) {
                _totalInactiveNodeOperator++;
            } else if (status == NodeOperatorStatus.ACTIVE) {
                _totalActiveNodeOperator++;
            } else if (status == NodeOperatorStatus.STOPPED) {
                _totalStoppedNodeOperator++;
            } else if (status == NodeOperatorStatus.UNSTAKED) {
                _totalUnstakedNodeOperator++;
            } else if (status == NodeOperatorStatus.CLAIMED) {
                _totalClaimedNodeOperator++;
            } else if (status == NodeOperatorStatus.JAILED) {
                _totalJailedNodeOperator++;
            } else if (status == NodeOperatorStatus.EJECTED) {
                _totalEjectedNodeOperator++;
            } else {
                _totalExitNodeOperator++;
            }
        }
    }

    /// @notice Get operatorIds.
    function getOperatorIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return operatorIds;
    }

    /// @notice Returns an operatorInfo list.
    /// @param _allWithStake if true return all operators with ACTIVE, EJECTED, JAILED.
    /// @param _delegation if true return all operators that delegation is set to true.
    /// @return Returns a list of operatorInfo.
    function getOperatorInfos(
        bool _delegation,
        bool _allWithStake
    ) external view override returns (Operator.OperatorInfo[] memory) {
        Operator.OperatorInfo[]
            memory operatorInfos = new Operator.OperatorInfo[](
                totalNodeOperators
            );

        uint256 length = operatorIds.length;
        uint256 index;

        for (uint256 idx = 0; idx < length; idx++) {
            uint256 operatorId = operatorIds[idx];
            NodeOperator storage no = operators[operatorId];
            NodeOperatorStatus status = getOperatorStatus(no);

            // if operator status is not ACTIVE we continue. But, if _allWithStake is true
            // we include EJECTED and JAILED operators.
            if (
                status != NodeOperatorStatus.ACTIVE &&
                !(_allWithStake &&
                    (status == NodeOperatorStatus.EJECTED ||
                        status == NodeOperatorStatus.JAILED))
            ) continue;

            // if true we check if the operator delegation is true.
            if (_delegation) {
                if (!IValidatorShare(no.validatorShare).delegation()) continue;
            }

            operatorInfos[index] = Operator.OperatorInfo({
                operatorId: operatorId,
                validatorShare: no.validatorShare,
                maxDelegateLimit: no.maxDelegateLimit,
                rewardAddress: no.rewardAddress
            });
            index++;
        }
        if (index != totalNodeOperators) {
            Operator.OperatorInfo[]
                memory operatorInfosOut = new Operator.OperatorInfo[](index);

            for (uint256 i = 0; i < index; i++) {
                operatorInfosOut[i] = operatorInfos[i];
            }
            return operatorInfosOut;
        }
        return operatorInfos;
    }

    /// @notice Checks condition and displays the message
    /// @param _condition a condition
    /// @param _message message to display
    function checkCondition(bool _condition, string memory _message)
        private
        pure
    {
        require(_condition, _message);
    }

    /// @notice Retrieve the operator struct based on the operatorId
    /// @param _operatorId id of the operator
    /// @return NodeOperator structure
    function getOperator(uint256 _operatorId)
        private
        view
        returns (uint256, NodeOperator storage)
    {
        if (_operatorId == 0) {
            _operatorId = getOperatorId(msg.sender);
        }
        NodeOperator storage no = operators[_operatorId];
        require(no.rewardAddress != address(0), "Operator not found");
        return (_operatorId, no);
    }

    /// @notice Retrieve the operator struct based on the operator owner address
    /// @param _user address of the operator owner
    /// @return NodeOperator structure
    function getOperatorId(address _user) private view returns (uint256) {
        uint256 operatorId = operatorOwners[_user];
        checkCondition(operatorId != 0, "Operator not found");
        return operatorId;
    }

    /// -------------------------------Events-----------------------------------

    /// @notice A new node operator was added.
    /// @param operatorId node operator id.
    event AddOperator(uint256 operatorId);

    /// @notice A new node operator joined.
    /// @param operatorId node operator id.
    event JoinOperator(uint256 operatorId);

    /// @notice A node operator was removed.
    /// @param operatorId node operator id.
    event RemoveOperator(uint256 operatorId);

    /// @param operatorId node operator id.
    event StopOperator(uint256 operatorId);

    /// @param operatorId node operator id.
    event MigrateOperator(uint256 operatorId);

    /// @notice A node operator was staked.
    /// @param operatorId node operator id.
    event StakeOperator(
        uint256 operatorId,
        uint256 amount,
        uint256 heimdallFees
    );

    /// @notice A node operator restaked.
    /// @param operatorId node operator id.
    /// @param amount amount to restake.
    /// @param restakeRewards restake rewards.
    event RestakeOperator(
        uint256 operatorId,
        uint256 amount,
        bool restakeRewards
    );

    /// @notice A node operator was unstaked.
    /// @param operatorId node operator id.
    event UnstakeOperator(uint256 operatorId);

    /// @notice TopUp heimadall fees.
    /// @param operatorId node operator id.
    /// @param amount amount.
    event TopUpHeimdallFees(uint256 operatorId, uint256 amount);

    /// @notice Withdraw rewards.
    /// @param operatorId node operator id.
    /// @param rewardAddress reward address.
    /// @param amount amount.
    event WithdrawRewards(
        uint256 operatorId,
        address rewardAddress,
        uint256 amount
    );

    /// @notice claims unstake.
    /// @param operatorId node operator id.
    /// @param amount amount.
    event UnstakeClaim(uint256 operatorId, uint256 amount);

    /// @notice update signer publickey.
    /// @param operatorId node operator id.
    event UpdateSignerPubkey(uint256 operatorId);

    /// @notice claim herimdall fee.
    /// @param operatorId node operator id.
    event ClaimFee(uint256 operatorId);

    /// @notice update commission rate.
    event UpdateCommissionRate(uint256 operatorId, uint256 newCommissionRate);

    /// @notice Unjail a validator.
    event Unjail(uint256 operatorId);

    /// @notice update operator name.
    event NewName(uint256 operatorId, string name);

    /// @notice update operator name.
    event NewRewardAddress(uint256 operatorId, address rewardAddress);
}