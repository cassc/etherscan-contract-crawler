// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import {SignatureUtil} from "../../../libraries/SignatureUtil.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum AssetType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155
}

// DO NOT CHANGE the struct, create a new order file instead.
// If chaging the struct is extremely necessary, don't forget to
// update the hash constant and hash function below.
struct TransferOrderV1 {
    
    address signer; // order signer

    // asset information
    AssetType assetType; // uint8
    address token; // token address
    uint256 tokenId; // irrelevant for ERC20 or native tokens
    address recipient; // recipient address

    // nonce to be able to cancel this order
    uint256 nonce;

    // signature parameters
    uint8 v;
    bytes32 r;
    bytes32 s;

    // On another note: maybe be careful when using bytes (no fixed) in this struct
    // Read the wyvern 2.2 exploit: https://nft.mirror.xyz/VdF3BYwuzXgLrJglw5xF6CHcQfAVbqeJVtueCr4BUzs
}

library TransferOrderV1Functions {
    
    bytes32 internal constant TransferOrderV1_HASH = 0xc05766abb1e6d2a75aa50d8336580fb44d1e8490756824d5bb5bcb97a8a29937;

    function hash(
        TransferOrderV1 memory passiveOrder
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TransferOrderV1_HASH,
                    passiveOrder.signer,
                    passiveOrder.assetType,
                    passiveOrder.token,
                    passiveOrder.tokenId,
                    passiveOrder.recipient,
                    passiveOrder.nonce
                )
            );
    }

    // Validate signatures (includes interaction with
    // other contracts)
    // Remember that we give away execution flow
    // in case the signer is a contract (isValidSignature)
    function validateSignatures(
        TransferOrderV1[] calldata orders,
        bytes32 domainSeparator
    ) public view {
        for (uint256 i = 0; i < orders.length; i++) {
            TransferOrderV1 calldata order = orders[i];
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

    function validateTransferOrdersParameters(
        mapping(address => mapping(uint256 => bool)) storage _isUsableNonce,
        IERC20 ownershipToken,
        TransferOrderV1[] calldata orders
    ) public view returns (uint256) {

        uint256 realContributionOnBoard = 0;
        // Validate orders parameters, no need to access state
        for (uint256 i = 0; i < orders.length; i++) {
            TransferOrderV1 calldata order = orders[i];

            // Validate AssetType is the same
            require(
                order.assetType == orders[0].assetType,
                "Order assetType mismatch"
            );

            // Validate token is the same
            require(
                order.token == orders[0].token,
                "Order token mismatch"
            );

            // Validate tokenId is the same
            require(
                order.tokenId == orders[0].tokenId,
                "Order tokenId mismatch"
            );

            // Validate recipient is the same
            require(
                order.recipient == orders[0].recipient,
                "Order recipient mismatch"
            );

            // Validating that the signer has not voted yet
            for (uint256 j = 0; j < i; j++) {
                if (orders[j].signer == order.signer) {
                    revert("Signer already voted");
                }
            }

            /* State required for the following lines */

            // Validate order nonce usability
            require(
                !_isUsableNonce[order.signer][order.nonce],
                "Order nonce is unusable"
            );
            // counting the "votes" in favor of this price
            realContributionOnBoard += ownershipToken.balanceOf(order.signer);
            
        } // ends the voters for loop

        return (realContributionOnBoard);
    }
}