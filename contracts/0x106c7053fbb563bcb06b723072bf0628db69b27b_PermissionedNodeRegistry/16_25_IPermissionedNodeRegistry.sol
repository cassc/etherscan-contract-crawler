// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '../library/ValidatorStatus.sol';
import './INodeRegistry.sol';

interface IPermissionedNodeRegistry {
    // Errors
    error NotAPermissionedNodeOperator();
    error OperatorAlreadyDeactivate();
    error OperatorAlreadyActive();
    error MaxOperatorLimitReached();

    // Events
    event OnboardedOperator(address indexed nodeOperator, address nodeRewardAddress, uint256 operatorId);
    event OperatorWhitelisted(address permissionedNO);
    event OperatorDeactivated(uint256 operatorID);
    event OperatorActivated(uint256 operatorID);
    event MaxOperatorIdLimitChanged(uint256 maxOperatorId);
    event MarkedValidatorStatusAsPreDeposit(bytes pubkey);
    event UpdatedQueuedValidatorIndex(uint256 indexed operatorId, uint256 nextQueuedValidatorIndex);

    // Getters

    function operatorIdForExcessDeposit() external view returns (uint256);

    function totalActiveOperatorCount() external view returns (uint256);

    function maxOperatorId() external view returns (uint256);

    function nextQueuedValidatorIndexByOperatorId(uint256) external view returns (uint256);

    function permissionList(address) external view returns (bool);

    function onlyPreDepositValidator(bytes calldata _pubkey) external view;

    // Setters

    function whitelistPermissionedNOs(address[] calldata _permissionedNOs) external;

    function onboardNodeOperator(string calldata _operatorName, address payable _operatorRewardAddress)
        external
        returns (address mevFeeRecipientAddress);

    function addValidatorKeys(
        bytes[] calldata _pubkey,
        bytes[] calldata _preDepositSignature,
        bytes[] calldata _depositSignature
    ) external;

    function allocateValidatorsAndUpdateOperatorId(uint256 _numValidators)
        external
        returns (uint256[] memory selectedOperatorCapacity);

    function activateNodeOperator(uint256 _operatorId) external;

    function deactivateNodeOperator(uint256 _operatorId) external;

    function increaseTotalActiveValidatorCount(uint256 _count) external;

    function updateQueuedValidatorIndex(uint256 _operatorId, uint256 _nextQueuedValidatorIndex) external;

    function updateDepositStatusAndBlock(uint256 _validatorId) external;

    function markValidatorStatusAsPreDeposit(bytes calldata _pubkey) external;

    function updateMaxNonTerminalKeyPerOperator(uint64 _maxNonTerminalKeyPerOperator) external;

    function updateInputKeyCountLimit(uint16 _inputKeyCountLimit) external;

    function updateOperatorDetails(string calldata _operatorName, address payable _rewardAddress) external;

    function pause() external;

    function unpause() external;
}