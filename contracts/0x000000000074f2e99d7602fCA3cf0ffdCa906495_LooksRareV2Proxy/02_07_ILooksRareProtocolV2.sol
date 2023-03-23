// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {Maker, Taker, MerkleTree} from "../libraries/looksrare-v2/OrderStructs.sol";

/**
 * @title ILooksRareProtocolV2
 * @author LooksRare protocol team (👀,💎)
 */
interface ILooksRareProtocolV2 {
    /**
     * @notice This function allows a user to execute a taker bid (against a maker ask).
     * @param takerBid Taker bid struct
     * @param makerAsk Maker ask struct
     * @param makerSignature Maker signature
     * @param merkleTree Merkle tree struct (if the signature contains multiple maker orders)
     * @param affiliate Affiliate address
     */
    function executeTakerBid(
        Taker calldata takerBid,
        Maker calldata makerAsk,
        bytes calldata makerSignature,
        MerkleTree calldata merkleTree,
        address affiliate
    ) external payable;

    /**
     * @notice This function allows a user to batch buy with an array of taker bids (against an array of maker asks).
     * @param takerBids Array of taker bid structs
     * @param makerAsks Array of maker ask structs
     * @param makerSignatures Array of maker signatures
     * @param merkleTrees Array of merkle tree structs if the signature contains multiple maker orders
     * @param affiliate Affiliate address
     * @param isAtomic Whether the execution should be atomic
     *        i.e. whether it should revert if 1 or more transactions fail
     */
    function executeMultipleTakerBids(
        Taker[] calldata takerBids,
        Maker[] calldata makerAsks,
        bytes[] calldata makerSignatures,
        MerkleTree[] calldata merkleTrees,
        address affiliate,
        bool isAtomic
    ) external payable;
}