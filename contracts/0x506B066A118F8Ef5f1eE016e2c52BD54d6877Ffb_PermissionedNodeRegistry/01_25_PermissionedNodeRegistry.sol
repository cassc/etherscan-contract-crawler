// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './library/ValidatorStatus.sol';
import './interfaces/IStaderConfig.sol';
import './interfaces/IVaultFactory.sol';
import './interfaces/IPoolUtils.sol';
import './interfaces/INodeRegistry.sol';
import './interfaces/IPermissionedPool.sol';
import './interfaces/IValidatorWithdrawalVault.sol';
import './interfaces/SDCollateral/ISDCollateral.sol';
import './interfaces/IPermissionedNodeRegistry.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

contract PermissionedNodeRegistry is
    INodeRegistry,
    IPermissionedNodeRegistry,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Math for uint256;

    uint8 public constant override POOL_ID = 2;
    uint16 public override inputKeyCountLimit;
    uint64 public override maxNonTerminalKeyPerOperator;

    IStaderConfig public staderConfig;

    uint256 public override nextValidatorId;
    uint256 public override totalActiveValidatorCount;
    uint256 public override verifiedKeyBatchSize;
    uint256 public override nextOperatorId;
    uint256 public override operatorIdForExcessDeposit;
    uint256 public override totalActiveOperatorCount;
    uint256 public override maxOperatorId;

    // mapping of validator Id and Validator struct
    mapping(uint256 => Validator) public override validatorRegistry;
    // mapping of bytes public key and validator Id
    mapping(bytes => uint256) public override validatorIdByPubkey;
    // mapping of operator Id and Operator struct
    mapping(uint256 => Operator) public override operatorStructById;
    // mapping of operator address and operator Id
    mapping(address => uint256) public override operatorIDByAddress;
    // mapping of whitelisted permissioned node operator
    mapping(address => bool) public override permissionList;
    //mapping of operator wise queued validator Ids arrays
    mapping(uint256 => uint256[]) public override validatorIdsByOperatorId;
    //mapping of operator Id and nextQueuedValidatorIndex
    mapping(uint256 => uint256) public override nextQueuedValidatorIndexByOperatorId;
    mapping(uint256 => uint256) public socializingPoolStateChangeBlock;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);
        __AccessControl_init_unchained();
        __Pausable_init();
        __ReentrancyGuard_init();
        staderConfig = IStaderConfig(_staderConfig);
        nextOperatorId = 1;
        nextValidatorId = 1;
        operatorIdForExcessDeposit = 1;
        inputKeyCountLimit = 50;
        maxOperatorId = 10;
        maxNonTerminalKeyPerOperator = 50;
        verifiedKeyBatchSize = 50;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice white list the permissioned node operator
     * @dev only `MANAGER` can call, whitelisting a one way change there is no blacklisting
     * @param _permissionedNOs array of permissioned NOs address
     */
    function whitelistPermissionedNOs(address[] calldata _permissionedNOs) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        uint256 permissionedNosLength = _permissionedNOs.length;
        for (uint256 i; i < permissionedNosLength; i++) {
            address operator = _permissionedNOs[i];
            UtilLib.checkNonZeroAddress(operator);
            permissionList[operator] = true;
            emit OperatorWhitelisted(operator);
        }
    }

    /**
     * @notice onboard a node operator
     * @dev only whitelisted NOs can call
     * @param _operatorName name of operator
     * @param _operatorRewardAddress eth1 address of operator to get rewards and withdrawals
     * @return feeRecipientAddress fee recipient address for all validator clients of a operator
     */
    function onboardNodeOperator(string calldata _operatorName, address payable _operatorRewardAddress)
        external
        override
        whenNotPaused
        returns (address feeRecipientAddress)
    {
        address poolUtils = staderConfig.getPoolUtils();
        if (IPoolUtils(poolUtils).poolAddressById(POOL_ID) != staderConfig.getPermissionedPool()) {
            revert DuplicatePoolIDOrPoolNotAdded();
        }
        IPoolUtils(poolUtils).onlyValidName(_operatorName);
        UtilLib.checkNonZeroAddress(_operatorRewardAddress);
        if (nextOperatorId > maxOperatorId) {
            revert MaxOperatorLimitReached();
        }
        if (!permissionList[msg.sender]) {
            revert NotAPermissionedNodeOperator();
        }
        //checks if operator already onboarded in any pool of protocol
        if (IPoolUtils(poolUtils).isExistingOperator(msg.sender)) {
            revert OperatorAlreadyOnBoardedInProtocol();
        }
        feeRecipientAddress = staderConfig.getPermissionedSocializingPool();
        onboardOperator(_operatorName, _operatorRewardAddress);
        return feeRecipientAddress;
    }

    /**
     * @notice add validator keys
     * @dev only accepts call from onboarded NOs along with sufficient SD lockup
     * @param _pubkey pubkey key of validators
     * @param _preDepositSignature signature of a validators for 1ETH deposit
     * @param _depositSignature signature of a validator for 31ETH deposit
     */
    function addValidatorKeys(
        bytes[] calldata _pubkey,
        bytes[] calldata _preDepositSignature,
        bytes[] calldata _depositSignature
    ) external override whenNotPaused {
        uint256 operatorId = onlyActiveOperator(msg.sender);
        (uint256 keyCount, uint256 operatorTotalKeys) = checkInputKeysCountAndCollateral(
            _pubkey.length,
            _preDepositSignature.length,
            _depositSignature.length,
            operatorId
        );

        address vaultFactory = staderConfig.getVaultFactory();
        address poolUtils = staderConfig.getPoolUtils();
        for (uint256 i; i < keyCount; ) {
            IPoolUtils(poolUtils).onlyValidKeys(_pubkey[i], _preDepositSignature[i], _depositSignature[i]);
            address withdrawVault = IVaultFactory(vaultFactory).deployWithdrawVault(
                POOL_ID,
                operatorId,
                operatorTotalKeys + i, //operator totalKeys
                nextValidatorId
            );
            validatorRegistry[nextValidatorId] = Validator(
                ValidatorStatus.INITIALIZED,
                _pubkey[i],
                _preDepositSignature[i],
                _depositSignature[i],
                withdrawVault,
                operatorId,
                0,
                0
            );
            validatorIdByPubkey[_pubkey[i]] = nextValidatorId;
            validatorIdsByOperatorId[operatorId].push(nextValidatorId);
            emit AddedValidatorKey(msg.sender, _pubkey[i], nextValidatorId);
            nextValidatorId++;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice operator selection logic
     * @dev first iteration is round robin based on capacity,
     * second iteration exhaust the capacity in sequential manner and
     * update the operatorId to pick operator for next sequence in next cycle
     * all array start with index 1
     * @param _numValidators validator to deposit with permissioned pool
     * @return selectedOperatorCapacity operator wise count of validator to deposit
     */
    function allocateValidatorsAndUpdateOperatorId(uint256 _numValidators)
        external
        override
        returns (uint256[] memory selectedOperatorCapacity)
    {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONED_POOL());
        // nextOperatorId is total operator count plus 1
        selectedOperatorCapacity = new uint256[](nextOperatorId);

        uint256 validatorPerOperator = _numValidators / totalActiveOperatorCount;
        uint256[] memory remainingOperatorCapacity = new uint256[](nextOperatorId);
        uint256 totalValidatorToDeposit;
        bool validatorPerOperatorGreaterThanZero = (validatorPerOperator > 0);
        if (validatorPerOperatorGreaterThanZero) {
            for (uint256 i = 1; i < nextOperatorId; i++) {
                if (!operatorStructById[i].active) {
                    continue;
                }
                remainingOperatorCapacity[i] = getOperatorQueuedValidatorCount(i);
                selectedOperatorCapacity[i] = Math.min(remainingOperatorCapacity[i], validatorPerOperator);
                totalValidatorToDeposit += selectedOperatorCapacity[i];
                remainingOperatorCapacity[i] -= selectedOperatorCapacity[i];
            }
        }

        // check for more validators to deposit and select operators with excess supply in a sequential order
        // and update the starting index of operator for next sequence after every iteration
        if (_numValidators > totalValidatorToDeposit) {
            uint256 totalOperators = nextOperatorId - 1;
            uint256 remainingValidatorsToDeposit = _numValidators - totalValidatorToDeposit;
            uint256 i = operatorIdForExcessDeposit;
            do {
                if (!operatorStructById[i].active) {
                    i = (i % totalOperators) + 1;
                    continue;
                }
                uint256 remainingCapacity = validatorPerOperatorGreaterThanZero
                    ? remainingOperatorCapacity[i]
                    : getOperatorQueuedValidatorCount(i);
                uint256 newSelectedCapacity = Math.min(remainingCapacity, remainingValidatorsToDeposit);
                selectedOperatorCapacity[i] += newSelectedCapacity;
                remainingValidatorsToDeposit -= newSelectedCapacity;
                i = (i % totalOperators) + 1;
                if (remainingValidatorsToDeposit == 0) {
                    operatorIdForExcessDeposit = i;
                    break;
                }
            } while (i != operatorIdForExcessDeposit);
        }
    }

    /**
     * @notice move validator state from PRE_DEPOSIT to DEPOSIT
     * after verifying pre-sign message, front running and deposit signature.
     * report front run and invalid signature pubkeys
     * @dev only `OPERATOR` role can call
     * @param _readyToDepositPubkey array of pubkeys ready to be moved to DEPOSIT state
     * @param _frontRunPubkey array for pubkeys which got front deposit
     * @param _invalidSignaturePubkey array of pubkey which has invalid signature for deposit
     */
    function markValidatorReadyToDeposit(
        bytes[] calldata _readyToDepositPubkey,
        bytes[] calldata _frontRunPubkey,
        bytes[] calldata _invalidSignaturePubkey
    ) external override nonReentrant whenNotPaused {
        UtilLib.onlyOperatorRole(msg.sender, staderConfig);
        uint256 readyToDepositValidatorsLength = _readyToDepositPubkey.length;
        uint256 frontRunValidatorsLength = _frontRunPubkey.length;
        uint256 invalidSignatureValidatorsLength = _invalidSignaturePubkey.length;

        if (
            readyToDepositValidatorsLength + frontRunValidatorsLength + invalidSignatureValidatorsLength >
            verifiedKeyBatchSize
        ) {
            revert TooManyVerifiedKeysReported();
        }

        //handle the front run validators
        for (uint256 i; i < frontRunValidatorsLength; ) {
            uint256 validatorId = validatorIdByPubkey[_frontRunPubkey[i]];
            // only PRE_DEPOSIT status check will also include validatorId = 0 check
            // as status for that will be INITIALIZED(default status)
            onlyPreDepositValidator(validatorId);
            handleFrontRun(validatorId);
            emit ValidatorMarkedAsFrontRunned(_frontRunPubkey[i], validatorId);
            unchecked {
                ++i;
            }
        }

        //handle the invalid signature validators
        for (uint256 i; i < invalidSignatureValidatorsLength; ) {
            uint256 validatorId = validatorIdByPubkey[_invalidSignaturePubkey[i]];
            // only PRE_DEPOSIT status check will also include validatorId = 0 check
            // as status for that will be INITIALIZED(default status)
            onlyPreDepositValidator(validatorId);
            validatorRegistry[validatorId].status = ValidatorStatus.INVALID_SIGNATURE;
            emit ValidatorStatusMarkedAsInvalidSignature(_invalidSignaturePubkey[i], validatorId);
            unchecked {
                ++i;
            }
        }

        address permissionedPool = staderConfig.getPermissionedPool();
        uint256 totalDefectedKeys = frontRunValidatorsLength + invalidSignatureValidatorsLength;
        if (totalDefectedKeys > 0) {
            decreaseTotalActiveValidatorCount(totalDefectedKeys);
            IPermissionedPool(permissionedPool).transferETHOfDefectiveKeysToSSPM(totalDefectedKeys);
        }
        IPermissionedPool(permissionedPool).fullDepositOnBeaconChain(_readyToDepositPubkey);
    }

    /**
     * @notice Flag fully withdrawn validators as reported by oracle.
     * @dev list of pubkeys reported by oracle, revert if terminal validators are reported
     * @param  _pubkeys array of withdrawn validators pubkey
     */
    function withdrawnValidators(bytes[] calldata _pubkeys) external override {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.STADER_ORACLE());
        uint256 withdrawnValidatorCount = _pubkeys.length;
        if (withdrawnValidatorCount > staderConfig.getWithdrawnKeyBatchSize()) {
            revert TooManyWithdrawnKeysReported();
        }
        for (uint256 i; i < withdrawnValidatorCount; ) {
            uint256 validatorId = validatorIdByPubkey[_pubkeys[i]];
            if (validatorRegistry[validatorId].status != ValidatorStatus.DEPOSITED) {
                revert UNEXPECTED_STATUS();
            }
            validatorRegistry[validatorId].status = ValidatorStatus.WITHDRAWN;
            validatorRegistry[validatorId].withdrawnBlock = block.number;
            IValidatorWithdrawalVault(validatorRegistry[validatorId].withdrawVaultAddress).settleFunds();
            emit ValidatorWithdrawn(_pubkeys[i], validatorId);
            unchecked {
                ++i;
            }
        }
        decreaseTotalActiveValidatorCount(withdrawnValidatorCount);
    }

    /**
     * @notice deactivate a node operator from running new validator clients
     * @dev only accept call from address having `MANAGER` role
     * @param _operatorId Id of the operator to deactivate
     */
    function deactivateNodeOperator(uint256 _operatorId) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        if (!operatorStructById[_operatorId].active) {
            revert OperatorAlreadyDeactivate();
        }
        _deactivateNodeOperator(_operatorId);
    }

    /**
     * @notice activate a node operator for running new validator clients
     * @dev only accept call from address having `MANAGER` role
     * @param _operatorId Id of the operator to activate
     */
    function activateNodeOperator(uint256 _operatorId) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        if (operatorStructById[_operatorId].active) {
            revert OperatorAlreadyActive();
        }
        _activateNodeOperator(_operatorId);
    }

    /**
     * @notice update the `nextQueuedValidatorIndex` for operator
     * @dev only permissioned pool can call
     * @param _operatorId Id of the node operator
     * @param _nextQueuedValidatorIndex updated next index of queued validator per operator
     */
    function updateQueuedValidatorIndex(uint256 _operatorId, uint256 _nextQueuedValidatorIndex) external override {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONED_POOL());
        nextQueuedValidatorIndexByOperatorId[_operatorId] = _nextQueuedValidatorIndex;
        emit UpdatedQueuedValidatorIndex(_operatorId, _nextQueuedValidatorIndex);
    }

    /**
     * @notice sets the deposit block for a validator and update status to DEPOSITED
     * @dev only permissioned pool can call
     * @param _validatorId Id of the validator
     */
    function updateDepositStatusAndBlock(uint256 _validatorId) external override {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONED_POOL());
        validatorRegistry[_validatorId].depositBlock = block.number;
        markValidatorDeposited(_validatorId);
        emit UpdatedValidatorDepositBlock(_validatorId, block.number);
    }

    /**
     * @notice update the status of a validator to `PRE_DEPOSIT`
     * @dev only `PERMISSIONED_POOL` role can call
     * @param _pubkey pubkey of the validator
     */
    function markValidatorStatusAsPreDeposit(bytes calldata _pubkey) external override {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONED_POOL());
        uint256 validatorId = validatorIdByPubkey[_pubkey];
        validatorRegistry[validatorId].status = ValidatorStatus.PRE_DEPOSIT;
        emit MarkedValidatorStatusAsPreDeposit(_pubkey);
    }

    /**
     * @notice update the name and reward address of an operator
     * @dev only operator msg.sender can update
     * @param _operatorName new Name of the operator
     * @param _rewardAddress new reward address
     */
    function updateOperatorDetails(string calldata _operatorName, address payable _rewardAddress) external override {
        IPoolUtils(staderConfig.getPoolUtils()).onlyValidName(_operatorName);
        UtilLib.checkNonZeroAddress(_rewardAddress);
        onlyActiveOperator(msg.sender);
        uint256 operatorId = operatorIDByAddress[msg.sender];
        operatorStructById[operatorId].operatorName = _operatorName;
        operatorStructById[operatorId].operatorRewardAddress = _rewardAddress;
        emit UpdatedOperatorDetails(msg.sender, _operatorName, _rewardAddress);
    }

    /**
     * @notice update the maximum non terminal key limit per operator
     * @dev only `MANAGER` role can call
     * @param _maxNonTerminalKeyPerOperator updated maximum non terminal key per operator limit
     */
    function updateMaxNonTerminalKeyPerOperator(uint64 _maxNonTerminalKeyPerOperator) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        maxNonTerminalKeyPerOperator = _maxNonTerminalKeyPerOperator;
        emit UpdatedMaxNonTerminalKeyPerOperator(maxNonTerminalKeyPerOperator);
    }

    /**
     * @notice update number of validator keys that can be added in a single tx by the operator
     * @dev only `OPERATOR` role can call
     * @param _inputKeyCountLimit updated maximum key limit in the input
     */
    function updateInputKeyCountLimit(uint16 _inputKeyCountLimit) external override {
        UtilLib.onlyOperatorRole(msg.sender, staderConfig);
        inputKeyCountLimit = _inputKeyCountLimit;
        emit UpdatedInputKeyCountLimit(inputKeyCountLimit);
    }

    /**
     * @notice update the max number of verified validator keys reported by oracle in single tx
     * @dev only `OPERATOR` can call
     * @param _verifiedKeysBatchSize updated maximum verified key limit in the oracle input
     */
    function updateVerifiedKeysBatchSize(uint256 _verifiedKeysBatchSize) external {
        UtilLib.onlyOperatorRole(msg.sender, staderConfig);
        verifiedKeyBatchSize = _verifiedKeysBatchSize;
        emit UpdatedVerifiedKeyBatchSize(_verifiedKeysBatchSize);
    }

    /**
     * @notice update the max operator Id value
     * @dev only `OPERATOR` can call
     * @param _maxOperatorId value of new max operator Id
     */
    function updateMaxOperatorId(uint256 _maxOperatorId) external {
        UtilLib.onlyOperatorRole(msg.sender, staderConfig);
        maxOperatorId = _maxOperatorId;
        emit MaxOperatorIdLimitChanged(_maxOperatorId);
    }

    /**
     * @notice update the address of staderConfig
     * @dev only `DEFAULT_ADMIN_ROLE` role can update
     */
    function updateStaderConfig(address _staderConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    // @inheritdoc INodeRegistry
    function getSocializingPoolStateChangeBlock(uint256 _operatorId) external view returns (uint256) {
        return socializingPoolStateChangeBlock[_operatorId];
    }

    /**
     * @notice increase the total active validator count
     * @dev only permissioned pool calls it when it does the deposit of 1 ETH for validator
     * @param _count count to increase total active validator value
     */
    function increaseTotalActiveValidatorCount(uint256 _count) external override {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONED_POOL());
        totalActiveValidatorCount += _count;
        emit IncreasedTotalActiveValidatorCount(totalActiveValidatorCount);
    }

    /**
     * @notice computes total queued keys for permissioned pool
     * @dev compute by looping over operators queued keys count
     * @return _validatorCount queued validator count
     */
    function getTotalQueuedValidatorCount() external view override returns (uint256) {
        uint256 totalQueuedValidators;
        for (uint256 i = 1; i < nextOperatorId; ) {
            if (operatorStructById[i].active) {
                totalQueuedValidators += getOperatorQueuedValidatorCount(i);
            }
            unchecked {
                ++i;
            }
        }
        return totalQueuedValidators;
    }

    /**
     * @notice returns total active keys for permissioned pool
     * @dev return the variable totalActiveValidatorCount
     * @return _validatorCount active validator count
     */
    function getTotalActiveValidatorCount() external view override returns (uint256) {
        return totalActiveValidatorCount;
    }

    /**
     * @notice get the total added keys for an operator
     * @dev length of the validatorIds array for an operator
     * @param _operatorId Id of node operator
     */
    function getOperatorTotalKeys(uint256 _operatorId) public view override returns (uint256 _totalKeys) {
        _totalKeys = validatorIdsByOperatorId[_operatorId].length;
    }

    /**
     * @param _nodeOperator @notice operator total non terminal keys within a specified validator list
     * @param _startIndex start index in validator queue to start with
     * @param _endIndex  up to end index of validator queue to to count
     */
    function getOperatorTotalNonTerminalKeys(
        address _nodeOperator,
        uint256 _startIndex,
        uint256 _endIndex
    ) public view override returns (uint64) {
        if (_startIndex > _endIndex) {
            revert InvalidStartAndEndIndex();
        }
        uint256 operatorId = operatorIDByAddress[_nodeOperator];
        uint256 validatorCount = getOperatorTotalKeys(operatorId);
        _endIndex = _endIndex > validatorCount ? validatorCount : _endIndex;
        uint64 totalNonWithdrawnKeyCount;
        for (uint256 i = _startIndex; i < _endIndex; ) {
            uint256 validatorId = validatorIdsByOperatorId[operatorId][i];
            if (isNonTerminalValidator(validatorId)) {
                totalNonWithdrawnKeyCount++;
            }
            unchecked {
                ++i;
            }
        }
        return totalNonWithdrawnKeyCount;
    }

    function getCollateralETH() external pure override returns (uint256) {
        return 0;
    }

    /**
     * @notice returns the operator reward address
     * @param _operatorId operator Id
     */
    function getOperatorRewardAddress(uint256 _operatorId) external view override returns (address payable) {
        return operatorStructById[_operatorId].operatorRewardAddress;
    }

    /**
     * @dev Triggers stopped state.
     * Contract must not be paused
     */
    function pause() external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Contract must be paused
     */
    function unpause() external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        _unpause();
    }

    /**
     * @notice Returns an array of active validators
     *
     * @param _pageNumber The page number of the results to fetch (starting from 1).
     * @param _pageSize The maximum number of items per page.
     *
     * @return An array of `Validator` objects representing the active validators.
     */
    function getAllActiveValidators(uint256 _pageNumber, uint256 _pageSize)
        external
        view
        override
        returns (Validator[] memory)
    {
        if (_pageNumber == 0) {
            revert PageNumberIsZero();
        }
        uint256 startIndex = (_pageNumber - 1) * _pageSize + 1;
        uint256 endIndex = startIndex + _pageSize;
        endIndex = endIndex > nextValidatorId ? nextValidatorId : endIndex;
        Validator[] memory validators = new Validator[](_pageSize);
        uint256 validatorCount;
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (isActiveValidator(i)) {
                validators[validatorCount] = validatorRegistry[i];
                validatorCount++;
            }
        }
        // If the result array isn't full, resize it to remove the unused elements
        assembly {
            mstore(validators, validatorCount)
        }

        return validators;
    }

    /**
     * @notice Returns an array of all validators for an Operator
     *
     * @param _pageNumber The page number of the results to fetch (starting from 1).
     * @param _pageSize The maximum number of items per page.
     *
     * @return An array of `Validator` objects representing all validators for an operator
     */
    function getValidatorsByOperator(
        address _operator,
        uint256 _pageNumber,
        uint256 _pageSize
    ) external view override returns (Validator[] memory) {
        if (_pageNumber == 0) {
            revert PageNumberIsZero();
        }
        uint256 startIndex = (_pageNumber - 1) * _pageSize;
        uint256 endIndex = startIndex + _pageSize;
        uint256 operatorId = operatorIDByAddress[_operator];
        if (operatorId == 0) {
            revert OperatorNotOnBoarded();
        }
        uint256 validatorCount = getOperatorTotalKeys(operatorId);
        endIndex = endIndex > validatorCount ? validatorCount : endIndex;
        Validator[] memory validators = new Validator[](endIndex > startIndex ? endIndex - startIndex : 0);
        for (uint256 i = startIndex; i < endIndex; i++) {
            uint256 validatorId = validatorIdsByOperatorId[operatorId][i];
            validators[i - startIndex] = validatorRegistry[validatorId];
        }

        return validators;
    }

    // check for duplicate keys in permissioned node registry
    function isExistingPubkey(bytes calldata _pubkey) external view override returns (bool) {
        return validatorIdByPubkey[_pubkey] != 0;
    }

    // check for duplicate operator in permissioned node registry
    function isExistingOperator(address _operAddr) external view override returns (bool) {
        return operatorIDByAddress[_operAddr] != 0;
    }

    // check for only PRE_DEPOSIT state validators
    function onlyPreDepositValidator(bytes calldata _pubkey) external view override {
        uint256 validatorId = validatorIdByPubkey[_pubkey];
        onlyPreDepositValidator(validatorId);
    }

    function onboardOperator(string calldata _operatorName, address payable _operatorRewardAddress) internal {
        operatorStructById[nextOperatorId] = Operator(true, true, _operatorName, _operatorRewardAddress, msg.sender);
        operatorIDByAddress[msg.sender] = nextOperatorId;
        socializingPoolStateChangeBlock[nextOperatorId] = block.number;
        nextOperatorId++;
        totalActiveOperatorCount++;
        emit OnboardedOperator(msg.sender, _operatorRewardAddress, nextOperatorId - 1);
    }

    // handle front run validator by changing their status and deactivating operator
    function handleFrontRun(uint256 _validatorId) internal {
        validatorRegistry[_validatorId].status = ValidatorStatus.FRONT_RUN;
        uint256 operatorId = validatorRegistry[_validatorId].operatorId;
        if (operatorStructById[operatorId].active) {
            _deactivateNodeOperator(operatorId);
        }
    }

    // returns operator total queued validator count
    function getOperatorQueuedValidatorCount(uint256 _operatorId) internal view returns (uint256 _validatorCount) {
        _validatorCount =
            validatorIdsByOperatorId[_operatorId].length -
            nextQueuedValidatorIndexByOperatorId[_operatorId];
    }

    // validate the input of `addValidatorKeys` function
    function checkInputKeysCountAndCollateral(
        uint256 _pubkeyLength,
        uint256 _preDepositSignatureLength,
        uint256 _depositSignatureLength,
        uint256 _operatorId
    ) internal view returns (uint256 keyCount, uint256 totalKeys) {
        if (_pubkeyLength != _preDepositSignatureLength || _pubkeyLength != _depositSignatureLength) {
            revert MisMatchingInputKeysSize();
        }
        keyCount = _pubkeyLength;
        if (keyCount == 0 || keyCount > inputKeyCountLimit) {
            revert InvalidKeyCount();
        }
        totalKeys = getOperatorTotalKeys(_operatorId);
        uint256 totalNonTerminalKeys = getOperatorTotalNonTerminalKeys(msg.sender, 0, totalKeys);
        if ((totalNonTerminalKeys + keyCount) > maxNonTerminalKeyPerOperator) {
            revert maxKeyLimitReached();
        }

        //checks if operator has enough SD collateral for adding `keyCount` keys
        //SD threshold for permissioned NOs is 0 for phase1
        if (
            !ISDCollateral(staderConfig.getSDCollateral()).hasEnoughSDCollateral(
                msg.sender,
                POOL_ID,
                totalNonTerminalKeys + keyCount
            )
        ) {
            revert NotEnoughSDCollateral();
        }
    }

    // operator in active state
    function onlyActiveOperator(address _operAddr) internal view returns (uint256 _operatorId) {
        _operatorId = operatorIDByAddress[_operAddr];
        if (_operatorId == 0) {
            revert OperatorNotOnBoarded();
        }
        if (!operatorStructById[_operatorId].active) {
            revert OperatorIsDeactivate();
        }
    }

    // checks if validator is active,
    //active validator are those having user deposit staked on beacon chain
    function isActiveValidator(uint256 _validatorId) internal view returns (bool) {
        Validator memory validator = validatorRegistry[_validatorId];
        return (validator.status == ValidatorStatus.PRE_DEPOSIT || validator.status == ValidatorStatus.DEPOSITED);
    }

    // checks if validator status enum is not withdrawn ,front run and invalid signature
    function isNonTerminalValidator(uint256 _validatorId) internal view returns (bool) {
        Validator memory validator = validatorRegistry[_validatorId];
        return
            !(validator.status == ValidatorStatus.WITHDRAWN ||
                validator.status == ValidatorStatus.FRONT_RUN ||
                validator.status == ValidatorStatus.INVALID_SIGNATURE);
    }

    // decreases the pool total active validator count
    function decreaseTotalActiveValidatorCount(uint256 _count) internal {
        totalActiveValidatorCount -= _count;
        emit DecreasedTotalActiveValidatorCount(totalActiveValidatorCount);
    }

    function onlyPreDepositValidator(uint256 _validatorId) internal view {
        if (validatorRegistry[_validatorId].status != ValidatorStatus.PRE_DEPOSIT) {
            revert UNEXPECTED_STATUS();
        }
    }

    function markValidatorDeposited(uint256 _validatorId) internal {
        validatorRegistry[_validatorId].status = ValidatorStatus.DEPOSITED;
    }

    function _deactivateNodeOperator(uint256 _operatorId) internal {
        operatorStructById[_operatorId].active = false;
        totalActiveOperatorCount--;
        emit OperatorDeactivated(_operatorId);
    }

    function _activateNodeOperator(uint256 _operatorId) internal {
        operatorStructById[_operatorId].active = true;
        totalActiveOperatorCount++;
        emit OperatorActivated(_operatorId);
    }
}