// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IVariableBalanceRecords } from './interfaces/IVariableBalanceRecords.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import './helpers/AddressHelper.sol' as AddressHelper;

/**
 * @title VariableBalanceRecords
 * @notice The contract for variable balance storage
 */
contract VariableBalanceRecords is SystemVersionId, BalanceManagement, IVariableBalanceRecords {
    /**
     * @dev Action executor contract reference
     */
    address public actionExecutor;

    /**
     * @dev Variable balance values by account and vault type
     */
    mapping(address /*account*/ => mapping(uint256 /*vaultType*/ => uint256 /*balance*/))
        public variableBalanceTable;

    /**
     * @notice Emitted when the action executor contract reference is set
     * @param actionExecutor The action executor contract address
     */
    event SetActionExecutor(address indexed actionExecutor);

    /**
     * @notice Emitted when the caller is not the action executor contract
     */
    error OnlyActionExecutorError();

    /**
     * @dev Modifier to check if the caller is the action executor contract
     */
    modifier onlyActionExecutor() {
        if (msg.sender != actionExecutor) {
            revert OnlyActionExecutorError();
        }

        _;
    }

    /**
     * @notice Deploys the VariableBalanceRecords contract
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(address _owner, address[] memory _managers, bool _addOwnerToManagers) {
        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Sets the action executor contract reference
     * @param _actionExecutor The action executor contract address
     */
    function setActionExecutor(address _actionExecutor) external onlyManager {
        AddressHelper.requireContract(_actionExecutor);

        actionExecutor = _actionExecutor;

        emit SetActionExecutor(_actionExecutor);
    }

    /**
     * @notice Increases the variable balance for the account
     * @param _account The account address
     * @param _vaultType The vault type
     * @param _amount The amount by which to increase the variable balance
     */
    function increaseBalance(
        address _account,
        uint256 _vaultType,
        uint256 _amount
    ) external onlyActionExecutor {
        variableBalanceTable[_account][_vaultType] += _amount;
    }

    /**
     * @notice Clears the variable balance for the account
     * @param _account The account address
     * @param _vaultType The vault type
     */
    function clearBalance(address _account, uint256 _vaultType) external onlyActionExecutor {
        variableBalanceTable[_account][_vaultType] = 0;
    }

    /**
     * @notice Getter of the variable balance by the account
     * @param _account The account address
     * @param _vaultType The vault type
     */
    function getAccountBalance(
        address _account,
        uint256 _vaultType
    ) external view returns (uint256) {
        return variableBalanceTable[_account][_vaultType];
    }
}