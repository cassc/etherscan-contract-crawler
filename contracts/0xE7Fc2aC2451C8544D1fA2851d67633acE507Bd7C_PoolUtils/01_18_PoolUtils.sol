// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './interfaces/IPoolUtils.sol';
import './interfaces/IStaderPoolBase.sol';
import './interfaces/IStaderConfig.sol';

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract PoolUtils is IPoolUtils, AccessControlUpgradeable {
    uint64 private constant PUBKEY_LENGTH = 48;
    uint64 private constant SIGNATURE_LENGTH = 96;
    IStaderConfig public staderConfig;

    mapping(uint8 => address) public override poolAddressById;
    uint8[] public override poolIdArray;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);
        __AccessControl_init_unchained();
        staderConfig = IStaderConfig(_staderConfig);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice Add a new pool.
     * @dev This function should only be called by the `MANAGER` role
     * @param _poolId Id of the pool.
     * @param _poolAddress The address of the new pool contract.
     */
    function addNewPool(uint8 _poolId, address _poolAddress) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        UtilLib.checkNonZeroAddress(_poolAddress);
        verifyNewPool(_poolId, _poolAddress);
        poolIdArray.push(_poolId);
        poolAddressById[_poolId] = _poolAddress;
        emit PoolAdded(_poolId, _poolAddress);
    }

    /**
     * @notice Update the address of a pool.
     * @dev This function should only be called by the `DEFAULT_ADMIN_ROLE` role
     * @param _poolId The Id of the pool to update.
     * @param _newPoolAddress The updated address of the pool.
     */
    function updatePoolAddress(uint8 _poolId, address _newPoolAddress)
        external
        override
        onlyExistingPoolId(_poolId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        UtilLib.checkNonZeroAddress(_newPoolAddress);
        verifyNewPool(_poolId, _newPoolAddress);
        poolAddressById[_poolId] = _newPoolAddress;
        emit PoolAddressUpdated(_poolId, _newPoolAddress);
    }

    /**
     * @notice validator pubkey list to exit for fulfilling user withdraw requests
     * @param _pubkeys list of validator pubkeys to exit
     * @dev emit an event containing validator pubkey for offchain to exit the validator
     */
    function processValidatorExitList(bytes[] calldata _pubkeys) external override {
        UtilLib.onlyOperatorRole(msg.sender, staderConfig);
        uint256 exitValidatorCount = _pubkeys.length;
        for (uint256 i; i < exitValidatorCount; ) {
            emit ExitValidator(_pubkeys[i]);
            unchecked {
                ++i;
            }
        }
    }

    //update the address of staderConfig
    function updateStaderConfig(address _staderConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    /// @inheritdoc IPoolUtils
    function getProtocolFee(uint8 _poolId) public view override onlyExistingPoolId(_poolId) returns (uint256) {
        return IStaderPoolBase(poolAddressById[_poolId]).protocolFee();
    }

    /// @inheritdoc IPoolUtils
    function getOperatorFee(uint8 _poolId) public view override onlyExistingPoolId(_poolId) returns (uint256) {
        return IStaderPoolBase(poolAddressById[_poolId]).operatorFee();
    }

    /// @inheritdoc IPoolUtils
    function getTotalActiveValidatorCount() external view override returns (uint256) {
        uint256 totalActiveValidatorCount;
        uint256 poolCount = getPoolCount();
        for (uint256 i; i < poolCount; i++) {
            totalActiveValidatorCount += getActiveValidatorCountByPool(poolIdArray[i]);
        }

        return totalActiveValidatorCount;
    }

    /// @inheritdoc IPoolUtils
    function getQueuedValidatorCountByPool(uint8 _poolId)
        external
        view
        override
        onlyExistingPoolId(_poolId)
        returns (uint256)
    {
        address nodeRegistry = getNodeRegistry(_poolId);
        return INodeRegistry(nodeRegistry).getTotalQueuedValidatorCount();
    }

    /// @inheritdoc IPoolUtils
    function getActiveValidatorCountByPool(uint8 _poolId)
        public
        view
        override
        onlyExistingPoolId(_poolId)
        returns (uint256)
    {
        address nodeRegistry = getNodeRegistry(_poolId);
        return INodeRegistry(nodeRegistry).getTotalActiveValidatorCount();
    }

    /// @inheritdoc IPoolUtils
    function getSocializingPoolAddress(uint8 _poolId)
        external
        view
        override
        onlyExistingPoolId(_poolId)
        returns (address)
    {
        return IStaderPoolBase(poolAddressById[_poolId]).getSocializingPoolAddress();
    }

    /// @inheritdoc IPoolUtils
    function getOperatorTotalNonTerminalKeys(
        uint8 _poolId,
        address _nodeOperator,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view override onlyExistingPoolId(_poolId) returns (uint256) {
        address nodeRegistry = getNodeRegistry(_poolId);
        return INodeRegistry(nodeRegistry).getOperatorTotalNonTerminalKeys(_nodeOperator, _startIndex, _endIndex);
    }

    function getCollateralETH(uint8 _poolId) public view override onlyExistingPoolId(_poolId) returns (uint256) {
        address nodeRegistry = getNodeRegistry(_poolId);
        return INodeRegistry(nodeRegistry).getCollateralETH();
    }

    function getNodeRegistry(uint8 _poolId) public view override onlyExistingPoolId(_poolId) returns (address) {
        return IStaderPoolBase(poolAddressById[_poolId]).getNodeRegistry();
    }

    function isExistingPubkey(bytes calldata _pubkey) public view override returns (bool) {
        uint256 poolCount = getPoolCount();
        for (uint256 i; i < poolCount; i++) {
            address nodeRegistry = getNodeRegistry(poolIdArray[i]);
            if (INodeRegistry(nodeRegistry).isExistingPubkey(_pubkey)) {
                return true;
            }
        }
        return false;
    }

    function isExistingOperator(address _operAddr) external view override returns (bool) {
        uint256 poolCount = getPoolCount();
        for (uint256 i; i < poolCount; i++) {
            address nodeRegistry = getNodeRegistry(poolIdArray[i]);
            if (INodeRegistry(nodeRegistry).isExistingOperator(_operAddr)) {
                return true;
            }
        }
        return false;
    }

    function getOperatorPoolId(address _operAddr) external view override returns (uint8) {
        uint256 poolCount = getPoolCount();
        for (uint256 i; i < poolCount; i++) {
            address nodeRegistry = getNodeRegistry(poolIdArray[i]);
            if (INodeRegistry(nodeRegistry).isExistingOperator(_operAddr)) {
                return poolIdArray[i];
            }
        }
        revert OperatorIsNotOnboarded();
    }

    function getValidatorPoolId(bytes calldata _pubkey) external view override returns (uint8) {
        uint256 poolCount = getPoolCount();
        for (uint256 i; i < poolCount; i++) {
            address nodeRegistry = getNodeRegistry(poolIdArray[i]);
            if (INodeRegistry(nodeRegistry).isExistingPubkey(_pubkey)) {
                return poolIdArray[i];
            }
        }
        revert PubkeyDoesNotExit();
    }

    function getPoolIdArray() external view override returns (uint8[] memory) {
        return poolIdArray;
    }

    // only valid name with string length limit
    function onlyValidName(string calldata _name) external view {
        if (bytes(_name).length == 0) {
            revert EmptyNameString();
        }
        if (bytes(_name).length > staderConfig.getOperatorMaxNameLength()) {
            revert NameCrossedMaxLength();
        }
    }

    // checks for keys lengths, and if pubkey is already present in stader protocol
    function onlyValidKeys(
        bytes calldata _pubkey,
        bytes calldata _preDepositSignature,
        bytes calldata _depositSignature
    ) external view {
        if (_pubkey.length != PUBKEY_LENGTH) {
            revert InvalidLengthOfPubkey();
        }
        if (_preDepositSignature.length != SIGNATURE_LENGTH) {
            revert InvalidLengthOfSignature();
        }
        if (_depositSignature.length != SIGNATURE_LENGTH) {
            revert InvalidLengthOfSignature();
        }
        if (isExistingPubkey(_pubkey)) {
            revert PubkeyAlreadyExist();
        }
    }

    //compute the share of rewards between user, protocol and operator
    function calculateRewardShare(uint8 _poolId, uint256 _totalRewards)
        external
        view
        override
        returns (
            uint256 userShare,
            uint256 operatorShare,
            uint256 protocolShare
        )
    {
        uint256 TOTAL_STAKED_ETH = staderConfig.getStakedEthPerNode();
        uint256 collateralETH = getCollateralETH(_poolId);
        uint256 usersETH = TOTAL_STAKED_ETH - collateralETH;
        uint256 protocolFeeBps = getProtocolFee(_poolId);
        uint256 operatorFeeBps = getOperatorFee(_poolId);

        uint256 _userShareBeforeCommission = (_totalRewards * usersETH) / TOTAL_STAKED_ETH;

        protocolShare = (protocolFeeBps * _userShareBeforeCommission) / staderConfig.getTotalFee();

        operatorShare = (_totalRewards * collateralETH) / TOTAL_STAKED_ETH;
        operatorShare += (operatorFeeBps * _userShareBeforeCommission) / staderConfig.getTotalFee();

        userShare = _totalRewards - protocolShare - operatorShare;
    }

    function isExistingPoolId(uint8 _poolId) public view override returns (bool) {
        uint256 poolCount = getPoolCount();
        for (uint256 i; i < poolCount; i++) {
            if (poolIdArray[i] == _poolId) {
                return true;
            }
        }
        return false;
    }

    function verifyNewPool(uint8 _poolId, address _poolAddress) internal view {
        if (
            INodeRegistry(IStaderPoolBase(_poolAddress).getNodeRegistry()).POOL_ID() != _poolId ||
            isExistingPoolId(_poolId)
        ) {
            revert ExistingOrMismatchingPoolId();
        }
    }

    function getPoolCount() internal view returns (uint256) {
        return poolIdArray.length;
    }

    // Modifiers
    modifier onlyExistingPoolId(uint8 _poolId) {
        if (!isExistingPoolId(_poolId)) {
            revert PoolIdNotPresent();
        }
        _;
    }
}