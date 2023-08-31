// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import {SignatureUtil} from "../../../libraries/SignatureUtil.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct FeeRecipient {
    uint256 amount;
    address payable recipient;
}

// DO NOT CHANGE the struct, create a new order file instead.
// If chaging the struct is extremely necessary, don't forget to
// update the hash constant and hash function below.
struct SellOrderV1 {
    
    address signer; // order signer

    // which of the nfts on the delegate is being sold
    address collection; // collection address
    uint256 tokenId; // tokenId

    // general sell order parameters
    uint256 minNetProceeds; // proceedings of the sale
    uint256 endTime; // sell order expiration time
    uint256 nonce;

    // additional fee recipients (marketplace and/or royalties, ...)
    FeeRecipient[] feeRecipients;

    // Seaport protocol addresses
    address seaport; // contract address
    address conduitController; // conduit address
    bytes32 conduitKey; // conduit key
    address zone; // zone address

    // signature parameters
    uint8 v;
    bytes32 r;
    bytes32 s;

    // On another note: maybe be careful when using bytes (no fixed) in this struct
    // Read the wyvern 2.2 exploit: https://nft.mirror.xyz/VdF3BYwuzXgLrJglw5xF6CHcQfAVbqeJVtueCr4BUzs
}

library SellOrderV1Functions {
    
    bytes32 internal constant SELLORDERV1_HASH = 0xa3caa541092a3d5698833496cbe4e751314b1700a1e16573464568ddd42cf878;
    bytes32 internal constant FEERECIPIENT_HASH = 0x65dcc86330d33f10b5643e98b00f9531f20a4af211fdfcb93f6e7813ff96ac5e;

    function hashFeeRecipient(FeeRecipient memory feeRecipient) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    FEERECIPIENT_HASH,
                    feeRecipient.amount,
                    feeRecipient.recipient
                )
            );
    }

    function hashFeeRecipients(FeeRecipient[] memory feeRecipients) internal pure returns (bytes32) {
        bytes32[] memory feeRecipientHashes = new bytes32[](feeRecipients.length);
        for (uint256 i = 0; i < feeRecipients.length; i++) {
            feeRecipientHashes[i] = hashFeeRecipient(feeRecipients[i]);
        }
        return keccak256(abi.encodePacked(feeRecipientHashes));
    }

    function hash(
        SellOrderV1 memory passiveOrder
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SELLORDERV1_HASH,
                    passiveOrder.signer,
                    passiveOrder.collection,
                    passiveOrder.tokenId,
                    passiveOrder.minNetProceeds,
                    passiveOrder.endTime,
                    passiveOrder.nonce,
                    hashFeeRecipients(passiveOrder.feeRecipients),
                    passiveOrder.seaport,
                    passiveOrder.conduitController,
                    passiveOrder.conduitKey,
                    passiveOrder.zone
                )
            );
    }

    // Validate signatures (includes interaction with
    // other contracts)
    // Remember that we give away execution flow
    // in case the signer is a contract (isValidSignature)
    function validateSignatures(
        SellOrderV1[] calldata orders,
        bytes32 domainSeparator
    ) public view {
        for (uint256 i = 0; i < orders.length; i++) {
            SellOrderV1 calldata order = orders[i];
            // Validate order signature
            bytes32 orderHash = hash(order);
            require(
                SignatureUtil.verify(
                    orderHash,
                    order.signer,
                    order.v,
                    order.r,
                    order.s,
                    domainSeparator
                ),
                "Signature: Invalid"
            );
        }
    }

    function validateSellOrdersParameters(
        mapping(address => mapping(uint256 => bool)) storage _isUsableNonce,
        IERC20 ownershipToken,
        SellOrderV1[] calldata orders
    ) public view returns (uint256, uint256, uint256) {

        uint256 minExpirationTime = type(uint256).max;
        uint256 maxOfMinProceeds = 0;
        uint256 realContributionOnBoard = 0;
        // Validate orders parameters, no need to access state
        for (uint256 i = 0; i < orders.length; i++) {
            SellOrderV1 calldata order = orders[i];

            // Validate the order is not expired
            require(order.endTime >= block.timestamp, "Order expired");

            // Validate collection is the same
            require(
                order.collection == orders[0].collection,
                "Order collection mismatch"
            );

            // Validate tokenId is the same
            require(
                order.tokenId == orders[0].tokenId,
                "Order tokenId mismatch"
            );

            // Validating that the signer has not voted yet
            for (uint256 j = 0; j < i; j++) {
                if (orders[j].signer == order.signer) {
                    revert("Signer already voted");
                }
            }

            // Validate fee recipients are the same
            require(
                order.feeRecipients.length == orders[0].feeRecipients.length,
                "Order feeRecipients length mismatch"
            );
            for (uint256 j = 0; j < order.feeRecipients.length; j++) {
                require(
                    order.feeRecipients[j].amount ==
                        orders[0].feeRecipients[j].amount,
                    "Order feeRecipients amount mismatch"
                );
                require(
                    order.feeRecipients[j].recipient ==
                        orders[0].feeRecipients[j].recipient,
                    "Order feeRecipients recipient mismatch"
                );
            }

            // Validate seaport is the same
            require(
                order.seaport == orders[0].seaport,
                "Order seaport mismatch"
            );

            // Validate conduitController is the same
            require(
                order.conduitController == orders[0].conduitController,
                "Order conduitController mismatch"
            );

            // Validate conduitKey is the same
            require(
                order.conduitKey == orders[0].conduitKey,
                "Order conduitKey mismatch"
            );

            // Validate zone is the same
            require(order.zone == orders[0].zone, "Order zone mismatch");


            // updating the min expiration time
            minExpirationTime = Math.min(
                minExpirationTime,
                order.endTime
            );
            // updating the max sell price
            maxOfMinProceeds = Math.max(maxOfMinProceeds, order.minNetProceeds);

            /* State required for the following lines */

            // Validate order nonce usability
            require(
                !_isUsableNonce[order.signer][order.nonce],
                "Order nonce is unusable"
            );
            // counting the "votes" in favor of this price
            realContributionOnBoard += ownershipToken.balanceOf(order.signer);
            
        } // ends the voters for loop

        return (minExpirationTime, maxOfMinProceeds, realContributionOnBoard);
    }
}