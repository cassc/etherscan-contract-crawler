// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {ReentrancyGuard} from "openzeppelin/utils/ReentrancyGuard.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {SpigotState, SpigotLib} from "../../utils/SpigotLib.sol";

import {ISpigot} from "../../interfaces/ISpigot.sol";

/**
 * @title   Credit Cooperative Spigot
 * @notice  - a contract allowing the revenue stream of a smart contract to be split between two parties, Owner and Treasury
            - operational control of revenue generating contract belongs to Spigot's Owner and delegated to Operator.
 * @dev     - Should be deployed once per agreement. Multiple revenue contracts can be attached to a Spigot.
 */
contract Spigot is ISpigot, ReentrancyGuard {
    using SpigotLib for SpigotState;

    // Stakeholder variables

    SpigotState private state;

    /**
     * @notice          - Configure data for Spigot stakeholders
     *                  - Owner/operator/treasury can all be the same address when setting up a Spigot
     * @param _owner    - An address that controls the Spigot and owns rights to some or all tokens earned by owned revenue contracts
     * @param _operator - An active address for non-Owner that can execute whitelisted functions to manage and maintain product operations
     *                  - on revenue generating contracts controlled by the Spigot.
     */
    constructor(address _owner, address _operator) {
        state.owner = _owner;
        state.operator = _operator;
    }

    function owner() external view returns (address) {
        return state.owner;
    }

    function operator() external view returns (address) {
        return state.operator;
    }

    // ##########################
    // #####   Claimoooor   #####
    // ##########################

    /**
     * @notice  - Claims revenue tokens from the Spigoted revenue contract and stores them for the Owner and Operator to withdraw later.
     *          - Accepts both push (tokens sent directly to Spigot) and pull payments (Spigot calls revenue contract to claim tokens)
     *          - Calls predefined function in contract settings to claim revenue.
     *          - Automatically sends portion to Treasury and then stores Owner and Operator shares
     *          - There is no conversion or trade of revenue tokens.
     * @dev     - Assumes the only side effect of calling claimFunc on revenueContract is we receive new tokens.
     *          - Any other side effects could be dangerous to the Spigot or upstream contracts.
     * @dev     - callable by anyone
     * @param revenueContract   - Contract with registered settings to claim revenue from
     * @param data              - Transaction data, including function signature, to properly claim revenue on revenueContract
     * @return claimed          -  The amount of revenue tokens claimed from revenueContract and split between `owner` and `treasury`
     */
    function claimRevenue(
        address revenueContract,
        address token,
        bytes calldata data
    ) external nonReentrant returns (uint256 claimed) {
        return state.claimRevenue(revenueContract, token, data);
    }

    /**
     * @notice  - Allows Spigot Owner to claim escrowed revenue tokens
     * @dev     - callable by `owner`
     * @param token     - address of revenue token that is being escrowed by spigot
     * @return claimed  -  The amount of tokens claimed by the `owner`
     */
    function claimOwnerTokens(address token) external nonReentrant returns (uint256 claimed) {
        return state.claimOwnerTokens(token);
    }

    /**
     * @notice - Allows Spigot Operqtor to claim escrowed revenue tokens
     * @dev - callable by `operator`
     * @param token - address of revenue token that is being escrowed by spigot
     * @return claimed -  The amount of tokens claimed by the `operator`
     */
    function claimOperatorTokens(address token) external nonReentrant returns (uint256 claimed) {
        return state.claimOperatorTokens(token);
    }

    // ##########################
    // ##### *ring* *ring*  #####
    // #####  OPERATOOOR    #####
    // #####  OPERATOOOR    #####
    // ##########################

    /**
     * @notice  - Allows Operator to call whitelisted functions on revenue contracts to maintain their product
     *          - while still allowing Spigot Owner to receive its revenue stream
     * @dev     - cannot call revenueContracts claim or transferOwner functions
     * @dev     - callable by `operator`
     * @param revenueContract   - contract to call. Must have existing settings added by Owner
     * @param data              - tx data, including function signature, to call contract with
     */
    function operate(address revenueContract, bytes calldata data) external returns (bool) {
        return state.operate(revenueContract, data);
    }

    // ##########################
    // #####  Maintainooor  #####
    // ##########################

    /**
     * @notice  - allows Owner to add a new revenue stream to the Spigot
     * @dev     - revenueContract cannot be address(this)
     * @dev     - callable by `owner`
     * @param revenueContract   - smart contract to claim tokens from
     * @param setting           - Spigot settings for smart contract
     */
    function addSpigot(address revenueContract, Setting memory setting) external returns (bool) {
        return state.addSpigot(revenueContract, setting);
    }

    /**

     * @notice  - Uses predefined function in revenueContract settings to transfer complete control and ownership from this Spigot to the Operator
     * @dev     - revenuContract's transfer func MUST only accept one paramteter which is the new owner's address.
     * @dev     - callable by `owner`
     * @param revenueContract - smart contract to transfer ownership of
     */
    function removeSpigot(address revenueContract) external returns (bool) {
        return state.removeSpigot(revenueContract);
    }

    /**
     * @notice  - Changes the revenue split between the Treasury and the Owner based upon the status of the Line of Credit
     *          - or otherwise if the Owner and Borrower wish to change the split.
     * @dev     - callable by `owner`
     * @param revenueContract - Address of spigoted revenue generating contract
     * @param ownerSplit - new % split to give owner
     */
    function updateOwnerSplit(address revenueContract, uint8 ownerSplit) external returns (bool) {
        return state.updateOwnerSplit(revenueContract, ownerSplit);
    }

    /**
     * @notice  - Update Owner role of Spigot contract.
     *          - New Owner receives revenue stream split and can control Spigot
     * @dev     - callable by `owner`
     * @param newOwner - Address to give control to
     */
    function updateOwner(address newOwner) external returns (bool) {
        return state.updateOwner(newOwner);
    }

    /**
     * @notice  - Update Operator role of Spigot contract.
     *          - New Operator can interact with revenue contracts.
     * @dev     - callable by `operator`
     * @param newOperator - Address to give control to
     */
    function updateOperator(address newOperator) external returns (bool) {
        return state.updateOperator(newOperator);
    }

    /**
     * @notice  - Allows Owner to whitelist function methods across all revenue contracts for Operator to call.
     *          - Can whitelist "transfer ownership" functions on revenue contracts
     *          - allowing Spigot to give direct control back to Operator.
     * @dev     - callable by `owner`
     * @param func      - smart contract function signature to whitelist
     * @param allowed   - true/false whether to allow this function to be called by Operator
     */
    function updateWhitelistedFunction(bytes4 func, bool allowed) external returns (bool) {
        return state.updateWhitelistedFunction(func, allowed);
    }

    // ##########################
    // #####   GETTOOOORS   #####
    // ##########################

    /**
     * @notice  - Retrieve amount of revenue tokens escrowed waiting for claim
     * @param token - Revenue token that is being garnished from spigots
     */
    function getOwnerTokens(address token) external view returns (uint256) {
        return state.ownerTokens[token];
    }

    /**
     * @notice - Retrieve amount of revenue tokens escrowed waiting for claim
     * @param token - Revenue token that is being garnished from spigots
     */
    function getOperatorTokens(address token) external view returns (uint256) {
        return state.operatorTokens[token];
    }

    /**
     * @notice - Returns if the function is whitelisted for an Operator to call
               - on the spigoted revenue generating smart contracts.
     * @param func - Function signature to check on whitelist
    */
    function isWhitelisted(bytes4 func) external view returns (bool) {
        return state.isWhitelisted(func);
    }

    function getSetting(address revenueContract) external view returns (uint8, bytes4, bytes4) {
        return state.getSetting(revenueContract);
    }

    receive() external payable {
        return;
    }
}