// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './library/ValidatorStatus.sol';
import './interfaces/IStaderConfig.sol';
import './interfaces/IVaultFactory.sol';
import './interfaces/IPoolUtils.sol';
import './interfaces/INodeRegistry.sol';
import './interfaces/IPermissionlessPool.sol';
import './interfaces/INodeELRewardVault.sol';
import './interfaces/IStaderInsuranceFund.sol';
import './interfaces/IValidatorWithdrawalVault.sol';
import './interfaces/SDCollateral/ISDCollateral.sol';
import './interfaces/IPermissionlessNodeRegistry.sol';
import './interfaces/IOperatorRewardsCollector.sol';

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

contract PermissionlessNodeRegistry is
    INodeRegistry,
    IPermissionlessNodeRegistry,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint8 public constant override POOL_ID = 1;
    uint16 public override inputKeyCountLimit;
    uint64 public override maxNonTerminalKeyPerOperator;

    IStaderConfig public staderConfig;

    uint256 public override verifiedKeyBatchSize;
    uint256 public override nextOperatorId;
    uint256 public override nextValidatorId;
    uint256 public override validatorQueueSize;
    uint256 public override nextQueuedValidatorIndex;
    uint256 public override totalActiveValidatorCount;
    uint256 public constant override FRONT_RUN_PENALTY = 3 ether;
    uint256 public constant COLLATERAL_ETH = 4 ether;

    // mapping of validator Id and Validator struct
    mapping(uint256 => Validator) public override validatorRegistry;
    // mapping of validator public key and validator Id
    mapping(bytes => uint256) public override validatorIdByPubkey;
    // Queued Validator queue
    mapping(uint256 => uint256) public override queuedValidators;
    // mapping of operator Id and Operator struct
    mapping(uint256 => Operator) public override operatorStructById;
    // mapping of operator address and operator Id
    mapping(address => uint256) public override operatorIDByAddress;
    //mapping of operator wise validator Ids arrays
    mapping(uint256 => uint256[]) public override validatorIdsByOperatorId;
    mapping(uint256 => uint256) public socializingPoolStateChangeBlock;
    //mapping of operator address with nodeELReward vault address
    mapping(uint256 => address) public override nodeELRewardVaultByOperatorId;

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
        inputKeyCountLimit = 30;
        maxNonTerminalKeyPerOperator = 50;
        verifiedKeyBatchSize = 50;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice onboard a node operator
     * @dev any one call, permissionless
     * @param _optInForSocializingPool opted in or not to socialize mev and priority fee
     * @param _operatorName name of operator
     * @param _operatorRewardAddress eth1 address of operator to get rewards and withdrawals
     * @return feeRecipientAddress fee recipient address for all validator clients of a operator
     */
    function onboardNodeOperator(
        bool _optInForSocializingPool,
        string calldata _operatorName,
        address payable _operatorRewardAddress
    ) external override whenNotPaused returns (address feeRecipientAddress) {
        address poolUtils = staderConfig.getPoolUtils();
        if (IPoolUtils(poolUtils).poolAddressById(POOL_ID) != staderConfig.getPermissionlessPool()) {
            revert DuplicatePoolIDOrPoolNotAdded();
        }
        IPoolUtils(poolUtils).onlyValidName(_operatorName);
        UtilLib.checkNonZeroAddress(_operatorRewardAddress);

        //checks if operator already onboarded in any pool of stader protocol
        if (IPoolUtils(poolUtils).isExistingOperator(msg.sender)) {
            revert OperatorAlreadyOnBoardedInProtocol();
        }
        //deploy NodeELRewardVault for NO
        address nodeELRewardVault = IVaultFactory(staderConfig.getVaultFactory()).deployNodeELRewardVault(
            POOL_ID,
            nextOperatorId
        );
        nodeELRewardVaultByOperatorId[nextOperatorId] = nodeELRewardVault;
        feeRecipientAddress = _optInForSocializingPool
            ? staderConfig.getPermissionlessSocializingPool()
            : nodeELRewardVault;
        onboardOperator(_optInForSocializingPool, _operatorName, _operatorRewardAddress);
        return feeRecipientAddress;
    }

    /**
     * @notice add validator keys
     * @dev only accepts if bond of 4 ETH per key is provided along with sufficient SD lockup
     * @param _pubkey pubkey of validators
     * @param _preDepositSignature signature of a validators for 1ETH deposit
     * @param _depositSignature signature of a validator for 31ETH deposit
     */
    function addValidatorKeys(
        bytes[] calldata _pubkey,
        bytes[] calldata _preDepositSignature,
        bytes[] calldata _depositSignature
    ) external payable override nonReentrant whenNotPaused {
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

        //slither-disable-next-line arbitrary-send-eth
        IPermissionlessPool(staderConfig.getPermissionlessPool()).preDepositOnBeaconChain{
            value: staderConfig.getPreDepositSize() * keyCount
        }(_pubkey, _preDepositSignature, operatorId, operatorTotalKeys);
    }

    /**
     * @notice move validator state from INITIALIZE to PRE_DEPOSIT
     * after verifying pre-sign message, front running and deposit signature.
     * report front run and invalid signature pubkeys
     * @dev only `OPERATOR` role can call
     * @param _readyToDepositPubkey array of pubkeys ready to be moved to PRE_DEPOSIT state
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

        for (uint256 i; i < readyToDepositValidatorsLength; ) {
            uint256 validatorId = validatorIdByPubkey[_readyToDepositPubkey[i]];
            onlyInitializedValidator(validatorId);
            markKeyReadyToDeposit(validatorId);
            emit ValidatorMarkedReadyToDeposit(_readyToDepositPubkey[i], validatorId);
            unchecked {
                ++i;
            }
        }

        if (frontRunValidatorsLength > 0) {
            IStaderInsuranceFund(staderConfig.getStaderInsuranceFund()).depositFund{
                value: frontRunValidatorsLength * FRONT_RUN_PENALTY
            }();
        }

        for (uint256 i; i < frontRunValidatorsLength; ) {
            uint256 validatorId = validatorIdByPubkey[_frontRunPubkey[i]];
            onlyInitializedValidator(validatorId);
            handleFrontRun(validatorId);
            emit ValidatorMarkedAsFrontRunned(_frontRunPubkey[i], validatorId);
            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < invalidSignatureValidatorsLength; ) {
            uint256 validatorId = validatorIdByPubkey[_invalidSignaturePubkey[i]];
            onlyInitializedValidator(validatorId);
            handleInvalidSignature(validatorId);
            emit ValidatorStatusMarkedAsInvalidSignature(_invalidSignaturePubkey[i], validatorId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice handling of fully withdrawn validators
     * @dev list of pubkeys reported by oracle
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
            if (!isActiveValidator(validatorId)) {
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
     * @notice update the next queued validator index by a count
     * @dev accept call from permissionless pool
     * @param _nextQueuedValidatorIndex updated next index of queued validator
     */
    function updateNextQueuedValidatorIndex(uint256 _nextQueuedValidatorIndex) external {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONLESS_POOL());
        nextQueuedValidatorIndex = _nextQueuedValidatorIndex;
        emit UpdatedNextQueuedValidatorIndex(nextQueuedValidatorIndex);
    }

    /**
     * @notice sets the deposit block for a validator
     * @dev only permissionless pool can call
     * @param _validatorId Id of the validator
     */
    function updateDepositStatusAndBlock(uint256 _validatorId) external override {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONLESS_POOL());
        validatorRegistry[_validatorId].depositBlock = block.number;
        markValidatorDeposited(_validatorId);
        emit UpdatedValidatorDepositBlock(_validatorId, block.number);
    }

    // allow NOs to opt in/out of socialize pool after coolDownPeriod
    function changeSocializingPoolState(bool _optInForSocializingPool)
        external
        override
        returns (address feeRecipientAddress)
    {
        uint256 operatorId = onlyActiveOperator(msg.sender);
        if (operatorStructById[operatorId].optedForSocializingPool == _optInForSocializingPool) {
            revert NoChangeInState();
        }

        if (
            block.number <
            socializingPoolStateChangeBlock[operatorId] + staderConfig.getSocializingPoolOptInCoolingPeriod()
        ) {
            revert CooldownNotComplete();
        }
        feeRecipientAddress = nodeELRewardVaultByOperatorId[operatorId];
        if (_optInForSocializingPool) {
            if (address(feeRecipientAddress).balance > 0) {
                INodeELRewardVault(feeRecipientAddress).withdraw();
            }
            feeRecipientAddress = staderConfig.getPermissionlessSocializingPool();
        }
        operatorStructById[operatorId].optedForSocializingPool = _optInForSocializingPool;
        socializingPoolStateChangeBlock[operatorId] = block.number;
        emit UpdatedSocializingPoolState(operatorId, _optInForSocializingPool, block.number);
    }

    // @inheritdoc INodeRegistry
    function getSocializingPoolStateChangeBlock(uint256 _operatorId) external view returns (uint256) {
        return socializingPoolStateChangeBlock[_operatorId];
    }

    /**
     * @notice update maximum key to be added in a batch
     * @dev only `OPERATOR` role can call
     * @param _inputKeyCountLimit updated maximum key limit in the input
     */
    function updateInputKeyCountLimit(uint16 _inputKeyCountLimit) external override {
        UtilLib.onlyOperatorRole(msg.sender, staderConfig);
        inputKeyCountLimit = _inputKeyCountLimit;
        emit UpdatedInputKeyCountLimit(inputKeyCountLimit);
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
     * @notice update the max number of verified validator keys reported by oracle
     * @dev only `OPERATOR` can call
     * @param _verifiedKeysBatchSize updated maximum verified key limit in the oracle input
     */
    function updateVerifiedKeysBatchSize(uint256 _verifiedKeysBatchSize) external {
        UtilLib.onlyOperatorRole(msg.sender, staderConfig);
        verifiedKeyBatchSize = _verifiedKeysBatchSize;
        emit UpdatedVerifiedKeyBatchSize(_verifiedKeysBatchSize);
    }

    //update the address of staderConfig
    function updateStaderConfig(address _staderConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    /**
     * @notice update the name and reward address of an operator
     * @dev only node operator can update
     * @param _operatorName new name of the operator
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
     * @notice increase the total active validator count
     * @dev only permissionless pool calls it when it does the deposit of 31ETH for validator
     * @param _count count to increase total active validator value
     */
    function increaseTotalActiveValidatorCount(uint256 _count) external override {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONLESS_POOL());
        totalActiveValidatorCount += _count;
        emit IncreasedTotalActiveValidatorCount(totalActiveValidatorCount);
    }

    /**
     * @notice transfer the `_amount` to permissionless pool
     * @dev only permissionless pool can call
     * @param _amount amount of eth to send to permissionless pool
     */
    function transferCollateralToPool(uint256 _amount) external override nonReentrant {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.PERMISSIONLESS_POOL());
        IPermissionlessPool(staderConfig.getPermissionlessPool()).receiveRemainingCollateralETH{value: _amount}();
        emit TransferredCollateralToPool(_amount);
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

    /**
     * @notice get the total added keys for an operator
     * @dev length of the validatorIds array for an operator
     * @param _operatorId Id of node operator
     */
    function getOperatorTotalKeys(uint256 _operatorId) public view override returns (uint256 _totalKeys) {
        _totalKeys = validatorIdsByOperatorId[_operatorId].length;
    }

    /**
     * @notice return total queued keys for permissionless pool
     * @return _validatorCount total queued validator count
     */
    function getTotalQueuedValidatorCount() external view override returns (uint256) {
        return validatorQueueSize - nextQueuedValidatorIndex;
    }

    /**
     * @notice return total active keys for permissionless pool
     * @return _validatorCount total active validator count
     */
    function getTotalActiveValidatorCount() external view override returns (uint256) {
        return totalActiveValidatorCount;
    }

    function getCollateralETH() external pure override returns (uint256) {
        return COLLATERAL_ETH;
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

    /**
     * @notice Returns an array of nodeELRewardVault address for all operators
     *
     * @param _pageNumber The page number of the results to fetch (starting from 1).
     * @param _pageSize The maximum number of items per page.
     *
     * @return An array of `address` objects representing the nodeELRewardVault contract address.
     */
    function getAllNodeELVaultAddress(uint256 _pageNumber, uint256 _pageSize)
        external
        view
        override
        returns (address[] memory)
    {
        if (_pageNumber == 0) {
            revert PageNumberIsZero();
        }
        uint256 startIndex = (_pageNumber - 1) * _pageSize + 1;
        uint256 endIndex = startIndex + _pageSize;
        endIndex = endIndex > nextOperatorId ? nextOperatorId : endIndex;
        address[] memory nodeELRewardVault = new address[](endIndex > startIndex ? endIndex - startIndex : 0);
        for (uint256 i = startIndex; i < endIndex; i++) {
            nodeELRewardVault[i - startIndex] = nodeELRewardVaultByOperatorId[i];
        }
        return nodeELRewardVault;
    }

    // check for duplicate keys in permissionless node registry
    function isExistingPubkey(bytes calldata _pubkey) external view override returns (bool) {
        return validatorIdByPubkey[_pubkey] != 0;
    }

    // check for duplicate operator in permissionless node registry
    function isExistingOperator(address _operAddr) external view override returns (bool) {
        return operatorIDByAddress[_operAddr] != 0;
    }

    function onboardOperator(
        bool _optInForSocializingPool,
        string calldata _operatorName,
        address payable _operatorRewardAddress
    ) internal {
        operatorStructById[nextOperatorId] = Operator(
            true,
            _optInForSocializingPool,
            _operatorName,
            _operatorRewardAddress,
            msg.sender
        );
        operatorIDByAddress[msg.sender] = nextOperatorId;
        socializingPoolStateChangeBlock[nextOperatorId] = block.number;
        nextOperatorId++;

        emit OnboardedOperator(msg.sender, _operatorRewardAddress, nextOperatorId - 1, _optInForSocializingPool);
    }

    // mark validator  `PRE_DEPOSIT` after successful key verification and front run check
    function markKeyReadyToDeposit(uint256 _validatorId) internal {
        validatorRegistry[_validatorId].status = ValidatorStatus.PRE_DEPOSIT;
        queuedValidators[validatorQueueSize] = _validatorId;
        validatorQueueSize++;
    }

    // handle front run validator by changing their status, deactivating operator and imposing penalty
    function handleFrontRun(uint256 _validatorId) internal {
        validatorRegistry[_validatorId].status = ValidatorStatus.FRONT_RUN;
        uint256 operatorId = validatorRegistry[_validatorId].operatorId;
        operatorStructById[operatorId].active = false;
    }

    // handle validator with invalid signature for 1ETH deposit
    //send back remaining ETH to operator address
    function handleInvalidSignature(uint256 _validatorId) internal {
        validatorRegistry[_validatorId].status = ValidatorStatus.INVALID_SIGNATURE;
        uint256 operatorId = validatorRegistry[_validatorId].operatorId;
        address operatorAddress = operatorStructById[operatorId].operatorAddress;
        IOperatorRewardsCollector(staderConfig.getOperatorRewardsCollector()).depositFor{
            value: (COLLATERAL_ETH - staderConfig.getPreDepositSize())
        }(operatorAddress);
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

        // check for collateral ETH for adding keys
        if (msg.value != keyCount * COLLATERAL_ETH) {
            revert InvalidBondEthValue();
        }
        //checks if operator has enough SD collateral for adding `keyCount` keys
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

    // checks if validator status enum is not withdrawn ,front run and invalid signature
    function isNonTerminalValidator(uint256 _validatorId) internal view returns (bool) {
        Validator memory validator = validatorRegistry[_validatorId];
        return
            !(validator.status == ValidatorStatus.WITHDRAWN ||
                validator.status == ValidatorStatus.FRONT_RUN ||
                validator.status == ValidatorStatus.INVALID_SIGNATURE);
    }

    // checks if validator is active,
    //active validator are those having user deposit staked on beacon chain
    function isActiveValidator(uint256 _validatorId) internal view returns (bool) {
        Validator memory validator = validatorRegistry[_validatorId];
        return validator.status == ValidatorStatus.DEPOSITED;
    }

    // decreases the pool total active validator count
    function decreaseTotalActiveValidatorCount(uint256 _count) internal {
        totalActiveValidatorCount -= _count;
        emit DecreasedTotalActiveValidatorCount(totalActiveValidatorCount);
    }

    function onlyInitializedValidator(uint256 _validatorId) internal view {
        if (_validatorId == 0 || validatorRegistry[_validatorId].status != ValidatorStatus.INITIALIZED) {
            revert UNEXPECTED_STATUS();
        }
    }

    function markValidatorDeposited(uint256 _validatorId) internal {
        validatorRegistry[_validatorId].status = ValidatorStatus.DEPOSITED;
    }
}