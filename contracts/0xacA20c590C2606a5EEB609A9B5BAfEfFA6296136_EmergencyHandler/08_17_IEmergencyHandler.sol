// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity ^0.8.0;

import {IBloomPool} from "./IBloomPool.sol";
import {IOracle} from "./IOracle.sol";

interface IEmergencyHandler {

    error BorrowerAlreadyClaimed();
    error CallerNotBloomPool();
    error NoTokensToRedeem();
    error NotWhitelisted();
    error PoolNotRegistered();
    error PoolAlreadyRegistered();
    error InvalidOwner();

    struct Token {
        address token;
        uint256 rate;
        uint256 rateDecimals;
    }

    struct PoolAccounting {
        uint256 lenderDistro; // Underlying assets available for lenders
        uint256 borrowerDistro; // Underlying assets available for borrowers
        uint256 lenderShares; // Total shares available for lenders
        uint256 borrowerShares; // Total shares available for borrowers
        uint256 totalUnderlying; // Total underlying assets from the pool
        uint256 totalBill; // Total bill assets from the pool
    }

    struct RedemptionInfo {
        Token underlyingToken;
        Token billToken;
        PoolAccounting accounting;
        bool yieldGenerated;
    }

    struct ClaimStatus {
        bool claimed;
        uint256 amountRemaining;
    }

    /**
     * @notice Redeem underlying assets for lenders of a BloomPool in Emergency Exit mode
     * @param _pool BloomPool that the funds in the emergency handler contract orginated from
     * @return amount of underlying assets redeemed
     */
    function redeem(IBloomPool _pool) external returns (uint256);

    /**
     * @notice  Redeem underlying assets for borrowers of a BloomPool in Emergency Exit mode
     * @param pool BloomPool that the funds in the emergency handler contract orginated from
     * @param id Id of the borrowers commit in the corresponding BloomPool
     * @return amount of underlying assets redeemed
     */
    function redeem(IBloomPool pool, uint256 id) external returns (uint256);

    /**
     * @notice Allows Market Makers to swap underlying assets for bill tokens
     * @param pool BloomPool that the funds in the emergency handler contract orginated from
     * @param underlyingIn Amount of underlying assets to swap
     * @param proof Whitelist proof data, prevents non-approved maket makers from swapping
     * @return amount of bill tokens received
     */
    function swap(IBloomPool pool, uint256 underlyingIn, bytes32[] calldata proof) external returns (uint256);
    
    /**
     * @notice Registers a Bloom Pool in the Emergency Handler
     * @param redemptionInfo RedemptionInfo struct containing the pool's accounting and oracle information
    */
    function registerPool(RedemptionInfo memory redemptionInfo) external;
}