// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {SignatureUtil} from "./../SignatureUtil.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Execution} from "./../execution/Execution.sol";

using BuyOrderV1Functions for BuyOrderV1 global;

// DO NOT CHANGE the struct, create a new order file instead.
// If chaging the struct is extremely necessary, don't forget to 
// update the hash constant and hash function below.
struct BuyOrderV1 {
    
    address signer; // order signer

    // general order parameters
    address collection; // collection address
    uint256 executionId; // buy order execution id
    uint256 contribution; // WETH contribution

    // buy order parameters
    uint256 buyPrice; // buy WETH price
    uint256 buyPriceEndTime; // order expiration time (set 0 for omitting)
    uint256 buyNonce; // for differentiating orders (it is not possible to re-use the nonce)

    // delegate
    address delegate;

    // signature parameters
    uint8 v;
    bytes32 r;
    bytes32 s;

    // On another note: maybe be careful when using bytes (no fixed) in this struct
    // Read the wyvern 2.2 exploit: https://nft.mirror.xyz/VdF3BYwuzXgLrJglw5xF6CHcQfAVbqeJVtueCr4BUzs
}

/**
 * @title PassiveTradeOrders
 * @notice
 */
library BuyOrderV1Functions {
    bytes32 internal constant PASSIVE_BUY_ORDER_HASH = 0x5747656214602028f3803e6af1a359d7948c36532bd38d033969d6c4b13e73eb;

    function hash(BuyOrderV1 memory passiveOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PASSIVE_BUY_ORDER_HASH,
                    passiveOrder.signer,
                    passiveOrder.collection,
                    passiveOrder.executionId,
                    passiveOrder.contribution,
                    passiveOrder.buyPrice,
                    passiveOrder.buyPriceEndTime,
                    passiveOrder.buyNonce,
                    passiveOrder.delegate
                )
            );
    }

    function canAcceptBuyPrice(BuyOrderV1 memory passiveOrder, uint256 price) internal pure returns (bool) {
        return passiveOrder.buyPrice >= price;
    }

    
    // Validate signatures (includes interaction with
    // other contracts)
    // Remember that we give away execution flow
    // in case the signer is a contract (isValidSignature)
    // function validateSignatures(
    //     BuyOrderV1[] calldata orders,
    //     bytes32 domainSeparator
    // ) public view {
    //     for (uint256 i = 0; i < orders.length; i++) {
    //         BuyOrderV1 calldata order = orders[i];
    //         // Validate order signature
    //         bytes32 orderHash = hash(order);
    //         require(
    //             SignatureUtil.verify(
    //                 orderHash,
    //                 order.signer,
    //                 order.v,
    //                 order.r,
    //                 order.s,
    //                 domainSeparator
    //             ),
    //             "Signature: Invalid"
    //         );
    //     }
    // }
}