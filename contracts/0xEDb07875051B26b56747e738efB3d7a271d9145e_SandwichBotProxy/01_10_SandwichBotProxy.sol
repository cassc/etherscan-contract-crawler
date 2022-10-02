// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "./interfaces/IResonateHelper.sol";
import "./interfaces/ISandwichBotProxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


/** @title Sandwich Bot Proxy. */
contract SandwichBotProxy is ISandwichBotProxy, AccessControl {

    /// Resonate Helper address
    address public RESONATE_HELPER;

    /// Declares CALLER, VOTER, ADMIN
    bytes32 public constant CALLER = 'CALLER';
    bytes32 public constant VOTER = 'VOTER';
    bytes32 public constant ADMIN = 'ADMIN';

    /**
     * @notice Sets up the sandwich bot proxy and its roles
     * @dev 
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _setupRole(CALLER, msg.sender);
        _setupRole(VOTER, msg.sender);
        _setRoleAdmin(CALLER, ADMIN);
        _setRoleAdmin(VOTER, ADMIN);
    }

    /**
     * @notice Initiates a meta-governance proxy call for a specific poolId with a list of operations to perform
     * @param poolId the pool to use the SmartWallet.sol deployment of for the meta-governance calls
     * @param targets a list of addresses to make calls against
     * @param values a list of Ether values to include in the calls
     * @param calldatas encoded calldata for the calls to-be-made
     */
    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external override onlyRole(VOTER) {
        IResonateHelper(RESONATE_HELPER).proxyCall(poolId, targets, values, calldatas);
    }

    /**
     * @notice sets up the ResonateHelper.sol contract during deployment
     * @param _resonateHelper the address of ResonateHelper.sol for this deployment
     */
    function setResonateHelper(address _resonateHelper) external onlyRole(ADMIN) {
        RESONATE_HELPER = _resonateHelper;
    }

    /**
     * @notice initiates a withdrawal/deposit of assets from a passed-in vaultAdapter for a given poolId
     * @param poolId the pool to target
     * @param amount the amount of tokens to withdraw/deposit
     * @param isWithdrawal whether to withdraw or deposit
     */
    function sandwichSnapshot(
        bytes32 poolId, 
        uint amount, 
        bool isWithdrawal
    ) external override onlyRole(CALLER) {
        IResonateHelper(RESONATE_HELPER).sandwichSnapshot(poolId, amount, isWithdrawal);
    }

}