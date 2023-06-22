// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '../library/ValidatorStatus.sol';
import './INodeRegistry.sol';

interface IPermissionlessNodeRegistry {
    // Errors
    error TransferFailed();
    error InvalidBondEthValue();
    error InSufficientBalance();
    error CooldownNotComplete();
    error NoChangeInState();

    // Events
    event OnboardedOperator(
        address indexed nodeOperator,
        address nodeRewardAddress,
        uint256 operatorId,
        bool optInForSocializingPool
    );
    event ValidatorMarkedReadyToDeposit(bytes pubkey, uint256 validatorId);
    event UpdatedNextQueuedValidatorIndex(uint256 nextQueuedValidatorIndex);
    event UpdatedSocializingPoolState(uint256 operatorId, bool optedForSocializingPool, uint256 block);
    event TransferredCollateralToPool(uint256 amount);

    //Getters

    function validatorQueueSize() external view returns (uint256);

    function nextQueuedValidatorIndex() external view returns (uint256);

    function FRONT_RUN_PENALTY() external view returns (uint256);

    function queuedValidators(uint256) external view returns (uint256);

    function nodeELRewardVaultByOperatorId(uint256) external view returns (address);

    function getAllNodeELVaultAddress(uint256 _pageNumber, uint256 _pageSize) external view returns (address[] memory);

    //Setters

    function onboardNodeOperator(
        bool _optInForMevSocialize,
        string calldata _operatorName,
        address payable _operatorRewardAddress
    ) external returns (address mevFeeRecipientAddress);

    function addValidatorKeys(
        bytes[] calldata _pubkey,
        bytes[] calldata _preDepositSignature,
        bytes[] calldata _depositSignature
    ) external payable;

    function updateNextQueuedValidatorIndex(uint256 _nextQueuedValidatorIndex) external;

    function updateDepositStatusAndBlock(uint256 _validatorId) external;

    function increaseTotalActiveValidatorCount(uint256 _count) external;

    function transferCollateralToPool(uint256 _amount) external;

    function updateInputKeyCountLimit(uint16 _batchKeyDepositLimit) external;

    function updateMaxNonTerminalKeyPerOperator(uint64 _maxNonTerminalKeyPerOperator) external;

    function updateOperatorDetails(string calldata _operatorName, address payable _rewardAddress) external;

    function changeSocializingPoolState(bool _optInForSocializingPool)
        external
        returns (address mevFeeRecipientAddress);

    function pause() external;

    function unpause() external;
}