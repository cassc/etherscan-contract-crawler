// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

import '../library/ValidatorStatus.sol';

struct Validator {
    ValidatorStatus status; // status of validator
    bytes pubkey; //pubkey of the validator
    bytes preDepositSignature; //signature for 1 ETH deposit on beacon chain
    bytes depositSignature; //signature for 31 ETH deposit on beacon chain
    address withdrawVaultAddress; //withdrawal vault address of validator
    uint256 operatorId; // stader network assigned Id
    uint256 depositBlock; // block number of the 31ETH deposit
    uint256 withdrawnBlock; //block number when oracle report validator as withdrawn
}

struct Operator {
    bool active; // operator status
    bool optedForSocializingPool; // operator opted for socializing pool
    string operatorName; // name of the operator
    address payable operatorRewardAddress; //Eth1 address of node for reward
    address operatorAddress; //address of operator to interact with stader
}

// Interface for the NodeRegistry contract
interface INodeRegistry {
    // Errors
    error DuplicatePoolIDOrPoolNotAdded();
    error OperatorAlreadyOnBoardedInProtocol();
    error maxKeyLimitReached();
    error OperatorNotOnBoarded();
    error InvalidKeyCount();
    error InvalidStartAndEndIndex();
    error OperatorIsDeactivate();
    error MisMatchingInputKeysSize();
    error PageNumberIsZero();
    error UNEXPECTED_STATUS();
    error PubkeyAlreadyExist();
    error NotEnoughSDCollateral();
    error TooManyVerifiedKeysReported();
    error TooManyWithdrawnKeysReported();

    // Events
    event AddedValidatorKey(address indexed nodeOperator, bytes pubkey, uint256 validatorId);
    event ValidatorMarkedAsFrontRunned(bytes pubkey, uint256 validatorId);
    event ValidatorWithdrawn(bytes pubkey, uint256 validatorId);
    event ValidatorStatusMarkedAsInvalidSignature(bytes pubkey, uint256 validatorId);
    event UpdatedValidatorDepositBlock(uint256 validatorId, uint256 depositBlock);
    event UpdatedMaxNonTerminalKeyPerOperator(uint64 maxNonTerminalKeyPerOperator);
    event UpdatedInputKeyCountLimit(uint256 batchKeyDepositLimit);
    event UpdatedStaderConfig(address staderConfig);
    event UpdatedOperatorDetails(address indexed nodeOperator, string operatorName, address rewardAddress);
    event IncreasedTotalActiveValidatorCount(uint256 totalActiveValidatorCount);
    event UpdatedVerifiedKeyBatchSize(uint256 verifiedKeysBatchSize);
    event UpdatedWithdrawnKeyBatchSize(uint256 withdrawnKeysBatchSize);
    event DecreasedTotalActiveValidatorCount(uint256 totalActiveValidatorCount);

    function withdrawnValidators(bytes[] calldata _pubkeys) external;

    function markValidatorReadyToDeposit(
        bytes[] calldata _readyToDepositPubkey,
        bytes[] calldata _frontRunPubkey,
        bytes[] calldata _invalidSignaturePubkey
    ) external;

    // return validator struct for a validator Id
    function validatorRegistry(uint256)
        external
        view
        returns (
            ValidatorStatus status,
            bytes calldata pubkey,
            bytes calldata preDepositSignature,
            bytes calldata depositSignature,
            address withdrawVaultAddress,
            uint256 operatorId,
            uint256 depositTime,
            uint256 withdrawnTime
        );

    // returns the operator struct given operator Id
    function operatorStructById(uint256)
        external
        view
        returns (
            bool active,
            bool optedForSocializingPool,
            string calldata operatorName,
            address payable operatorRewardAddress,
            address operatorAddress
        );

    // Returns the last block the operator changed the opt-in status for socializing pool
    function getSocializingPoolStateChangeBlock(uint256 _operatorId) external view returns (uint256);

    function getAllActiveValidators(uint256 _pageNumber, uint256 _pageSize) external view returns (Validator[] memory);

    function getValidatorsByOperator(
        address _operator,
        uint256 _pageNumber,
        uint256 _pageSize
    ) external view returns (Validator[] memory);

    /**
     *
     * @param _nodeOperator @notice operator total non withdrawn keys within a specified validator list
     * @param _startIndex start index in validator queue to start with
     * @param _endIndex  up to end index of validator queue to to count
     */
    function getOperatorTotalNonTerminalKeys(
        address _nodeOperator,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (uint64);

    // returns the total number of queued validators across all operators
    function getTotalQueuedValidatorCount() external view returns (uint256);

    // returns the total number of active validators across all operators
    function getTotalActiveValidatorCount() external view returns (uint256);

    function getCollateralETH() external view returns (uint256);

    function getOperatorTotalKeys(uint256 _operatorId) external view returns (uint256 totalKeys);

    function operatorIDByAddress(address) external view returns (uint256);

    function getOperatorRewardAddress(uint256 _operatorId) external view returns (address payable);

    function isExistingPubkey(bytes calldata _pubkey) external view returns (bool);

    function isExistingOperator(address _operAddr) external view returns (bool);

    function POOL_ID() external view returns (uint8);

    function inputKeyCountLimit() external view returns (uint16);

    function nextOperatorId() external view returns (uint256);

    function nextValidatorId() external view returns (uint256);

    function maxNonTerminalKeyPerOperator() external view returns (uint64);

    function verifiedKeyBatchSize() external view returns (uint256);

    function totalActiveValidatorCount() external view returns (uint256);

    function validatorIdByPubkey(bytes calldata _pubkey) external view returns (uint256);

    function validatorIdsByOperatorId(uint256, uint256) external view returns (uint256);
}