// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

import {AssetCommitment} from "./lib/CommitmentsLib.sol";
import {ExchangeRateRegistry} from "./helpers/ExchangeRateRegistry.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IBloomPool} from "./interfaces/IBloomPool.sol";
import {IEmergencyHandler, IOracle} from "./interfaces/IEmergencyHandler.sol";
import {ISwapFacility} from "./interfaces/ISwapFacility.sol";

/**
 * @title EmergencyHandler
 * @notice Allows users to redeem their funds from a Bloom Pool in emergency mode
 * @dev This contract must correspond to a specific ExchangeRateRegistry
 */
contract EmergencyHandler is IEmergencyHandler, Ownable2Step {
    using SafeTransferLib for address;
    // =================== Storage ===================

    ExchangeRateRegistry public immutable REGISTRY;
    mapping(address => RedemptionInfo) public redemptionInfo;
    mapping(address => mapping(uint256 => ClaimStatus)) public borrowerClaimStatus;

    // ================== Modifiers ==================

    modifier onlyPool() {
        (bool registered, , ) = REGISTRY.tokenInfos(msg.sender);
        if (!registered) revert CallerNotBloomPool();
        _;
    }

    modifier onlyWhitelisted(IBloomPool pool, bytes32[] calldata proof) {
        if (!ISwapFacility(pool.SWAP_FACILITY()).whitelist().isWhitelisted(msg.sender, proof)) {
            revert NotWhitelisted();
        }
        _;
    }

    constructor(ExchangeRateRegistry _registry) Ownable2Step() {
        REGISTRY = _registry;
    }

    /**
     * @inheritdoc IEmergencyHandler
     */
    function redeem(IBloomPool pool) external override returns (uint256) {
        uint256 claimAmount;
        // Get data for the associated pool
        RedemptionInfo memory info = redemptionInfo[address(pool)];
        Token memory underlyingInfo = info.underlyingToken;

        address underlyingToken = underlyingInfo.token;
        if (underlyingToken == address(0)) revert PoolNotRegistered();
        uint256 tokenAmount = ERC20(address(pool)).balanceOf(msg.sender);

        // Calculate the amount of underlying tokens to send to the user
        if (info.yieldGenerated) {
            claimAmount =
                (tokenAmount * info.accounting.lenderDistro) /
                info.accounting.lenderShares;
        } else {
            claimAmount = tokenAmount;
        }

        // Update the claim amount if it is greater than the current availablity of underlying tokens
        if (claimAmount > info.accounting.lenderDistro) claimAmount = info.accounting.lenderDistro;
        if (claimAmount > info.accounting.totalUnderlying) claimAmount = info.accounting.totalUnderlying;

        uint256 burnAmount = info.accounting.lenderShares * claimAmount / info.accounting.lenderDistro;

        info.accounting.lenderDistro -= claimAmount;
        info.accounting.lenderShares -= burnAmount;
        info.accounting.totalUnderlying -= claimAmount;

        if (burnAmount == 0 || claimAmount == 0) revert NoTokensToRedeem();
        pool.executeEmergencyBurn(msg.sender, burnAmount);
        underlyingToken.safeTransfer(msg.sender, claimAmount);

        return claimAmount;
    }

    /**
     * @inheritdoc IEmergencyHandler
     */
    function redeem(
        IBloomPool pool,
        uint256 id
    ) external override returns (uint256) {
        uint256 claimAmount;
        // Get data for the associated pool
        RedemptionInfo memory info = redemptionInfo[address(pool)];
        PoolAccounting memory accounting = info.accounting;

        AssetCommitment memory commitment = pool.getBorrowCommitment(id);
        ClaimStatus memory claimStatus = borrowerClaimStatus[address(pool)][id];
        if (accounting.borrowerShares == 0) revert NoTokensToRedeem();

        address underlyingToken = info.underlyingToken.token;
        if (underlyingToken == address(0)) revert PoolNotRegistered();
        uint256 commitmentAvailable = commitment.committedAmount;

        if (commitment.owner != msg.sender) revert InvalidOwner();
        
        // If the user has already claimed, update how much they can claim this round
        if (claimStatus.claimed) {
            commitmentAvailable = claimStatus.amountRemaining;
        } 

        // Calculate the amount of underlying tokens to send to the user
        if (info.yieldGenerated) {
            claimAmount = commitmentAvailable * accounting.borrowerDistro / accounting.borrowerShares;
        } else {
            claimAmount = commitmentAvailable;
        }

        // Update the claim amount if it is greater than the current availablity of underlying tokens
        if (claimAmount > accounting.borrowerDistro) claimAmount = accounting.borrowerDistro;
        if (claimAmount > accounting.totalUnderlying) claimAmount = accounting.totalUnderlying;

        uint256 commitmentUsed = claimAmount * accounting.borrowerShares / accounting.borrowerDistro;

        // Update accounting data
        redemptionInfo[address(pool)].accounting.borrowerDistro -= claimAmount;
        redemptionInfo[address(pool)].accounting.borrowerShares -= commitmentUsed;
        redemptionInfo[address(pool)].accounting.totalUnderlying -= claimAmount;


        if (commitmentUsed == 0 || claimAmount == 0) revert NoTokensToRedeem();

        // Update claim status
        borrowerClaimStatus[address(pool)][id] = ClaimStatus({
            claimed: true,
            amountRemaining: commitmentAvailable - commitmentUsed
        });
        
        // Transfer tokens to borrower
        underlyingToken.safeTransfer(msg.sender, claimAmount);
        return claimAmount;
    }

    /**
     * @inheritdoc IEmergencyHandler
     */
    function swap(
        IBloomPool pool,
        uint256 underlyingIn,
        bytes32[] calldata proof
    ) external override onlyWhitelisted(pool, proof) returns (uint256) {
        // Get data for the associated pool
        RedemptionInfo memory info = redemptionInfo[address(pool)];
        Token memory underlyingToken = info.underlyingToken;
        Token memory billToken = info.billToken;

        // Calculate the amount of bill tokens to send to the user
        uint256 scalingFactor = 10**(billToken.rateDecimals - underlyingToken.rateDecimals);

        uint256 inTokenPrice = underlyingToken.rate;
        uint256 outTokenPrice = billToken.rate;
        uint256 outAmount = underlyingIn * inTokenPrice * scalingFactor / outTokenPrice;
        
        // Update the amount if it is greater than the current availablity of bill tokens
        if (outAmount > info.accounting.totalBill) {
            outAmount = info.accounting.totalBill;
            // Recalculate the amount of underlying tokens to send to the user
            underlyingIn = outAmount * outTokenPrice / inTokenPrice / scalingFactor;
        }

        // Update accounting data
        redemptionInfo[address(pool)].accounting = PoolAccounting({
            lenderDistro: info.accounting.lenderDistro,
            borrowerDistro: info.accounting.borrowerDistro,
            lenderShares: info.accounting.lenderShares,
            borrowerShares: info.accounting.borrowerShares,
            totalUnderlying: info.accounting.totalUnderlying + underlyingIn,
            totalBill: info.accounting.totalBill - outAmount
        });

        // Complete the swap
        underlyingToken.token.safeTransferFrom(
            msg.sender,
            address(this),
            underlyingIn
        );
        billToken.token.safeTransfer(msg.sender, outAmount);

        return outAmount;
    }

    /**
     * @inheritdoc IEmergencyHandler
     */
    function registerPool(
        RedemptionInfo memory info
    ) external override onlyPool {
        if (redemptionInfo[msg.sender].underlyingToken.token != address(0)) {
            revert PoolAlreadyRegistered();
        }
        redemptionInfo[msg.sender] = info;
    }
}