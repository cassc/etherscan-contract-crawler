// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {LibSignatures} from "../libraries/LibSignatures.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/// "Call to method failed"
error OneInchCallFailed();
/// "Invalid 1nch source"
error Invalid1nchSource();
/// "Invalid 1nch limit order filled maker"
error InvalidLimitOrderFill();

// address constant LIMIT_ORDER_PROTOCOL_1NCH = 0x94Bc2a1C732BcAd7343B25af48385Fe76E08734f; // 1nch Polygon LimitOrderProtocol

address constant LIMIT_ORDER_PROTOCOL_1NCH = 0x119c71D3BbAC22029622cbaEc24854d3D32D2828; // 1nch Mainnet LimitOrderProtocol

// address constant LIMIT_ORDER_PROTOCOL_1NCH = 0x11431a89893025D2a48dCA4EddC396f8C8117187; // 1nch Optimism LimitOrderProtocol

/**
 * @title LimitOrdersFacet
 * @author PartyFinance
 * @notice Facet that interacts with 1nch Protocol to handle LimitOrders
 * [1nch LimitOrder introduction](https://docs.1inch.io/docs/limit-order-protocol/introduction)
 */
contract LimitOrdersFacet is Modifiers {
    /**
     * @notice Emitted when 1nch LimitOrderProtocol calls Party when a limit order is filled
     * @param taker Taker address that filled the order
     * @param makerAsset Maker asset address
     * @param takerAsset Taker asset address
     * @param makingAmount Making asset amount
     * @param takingAmount Taking asset amount
     */
    event LimitOrderFilled(
        address taker,
        address makerAsset,
        address takerAsset,
        uint256 makingAmount,
        uint256 takingAmount
    );

    struct LimitOrder {
        uint256 salt;
        address makerAsset;
        address takerAsset;
        address maker;
        address receiver;
        address allowedSender;
        uint256 makingAmount;
        uint256 takingAmount;
        bytes makerAssetData;
        bytes takerAssetData;
        bytes getMakerAmount;
        bytes getTakerAmount;
        bytes predicate;
        bytes permit;
        bytes interaction;
    }

    /**
     * @notice Approves 1nch LimitOrderProtocol to consume party assets
     * @param sellToken ERC-20 sell token address
     * @param sellAmount ERC-20 sell token amount
     */
    function approveLimitOrder(
        address sellToken,
        uint256 sellAmount
    ) external onlyManager {
        // Execute 1nch cancelOrder method
        IERC20(sellToken).approve(LIMIT_ORDER_PROTOCOL_1NCH, sellAmount);
    }

    /**
     * @notice Cancels a limit order on 1nch
     * @param order Limit Order
     */
    function cancelLimitOrder(LimitOrder memory order) external onlyManager {
        // Execute 1nch cancelOrder method
        (bool success, ) = LIMIT_ORDER_PROTOCOL_1NCH.call(
            abi.encodeWithSignature(
                "cancelOrder((uint256,address,address,address,address,address,uint256,uint256,bytes,bytes,bytes,bytes,bytes,bytes,bytes))",
                order
            )
        );
        if (!success) revert OneInchCallFailed();
    }

    /**
     * @notice Interaction receiver function for 1nch LimitOrderProtocol when a party's limit order is filled
     * @param taker Taker address that filled the order
     * @param makerAsset Maker asset address
     * @param takerAsset Taker asset address
     * @param makingAmount Making asset amount
     * @param takingAmount Taking asset amount
     * @param interactiveData Interactive call data
     */
    function notifyFillOrder(
        address taker,
        address makerAsset,
        address takerAsset,
        uint256 makingAmount,
        uint256 takingAmount,
        bytes calldata interactiveData
    ) external {
        if (msg.sender != LIMIT_ORDER_PROTOCOL_1NCH) revert Invalid1nchSource();
        address makerAddress;
        assembly {
            makerAddress := shr(96, calldataload(interactiveData.offset))
        }
        if (makerAddress != address(this)) revert InvalidLimitOrderFill();
        emit LimitOrderFilled(
            taker,
            makerAsset,
            takerAsset,
            makingAmount,
            takingAmount
        );
    }

    /**
     * @notice Standard Signature Validation Method for Contracts EIP-1271.
     * @dev Verifies that the signer is a Party Manager of the signing contract.
     */
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bytes4) {
        if (s.managers[LibSignatures.recover(_hash, _signature)]) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }
}