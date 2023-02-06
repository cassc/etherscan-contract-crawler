// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {MerkleList} from "src/contracts/modules/utils/MerkleList.sol";
import {NativePrice} from "src/contracts/modules/utils/NativePrice.sol";
import {MinterTracker} from "src/contracts/modules/utils/MinterTracker.sol";
import {ERC165CheckerERC721Collective} from "src/contracts/ERC721Collective/ERC165CheckerERC721Collective.sol";
import {IERC721Collective} from "src/contracts/ERC721Collective/IERC721Collective.sol";
import {TokenRecoverable} from "src/contracts/utils/TokenRecoverable/TokenRecoverable.sol";

/**
 * @title AdditionalNativeTokenPriceMerkleMintModule
 * @author Syndicate Inc.
 * @dev This is an additional mint module for Merkle claims. It is identical to
 * NativeTokenPriceMerkleMintModule, but the additional deployment allows us to
 * have two different claim amounts for a single Collective. The
 * NativeTokenPriceMerkleMintModule should be preferred, this exists only as an
 * additional fallback.
 *
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * A Module that allows the owner of an ERC721Collective to "airdrop" a list of
 * recipient addresses and mint amounts as a Merkle tree, and allows recipients
 * on that list to mint their allocated tokens in exchange for a native
 * token-denominated price per token set by the owner.
 */
contract AdditionalNativeTokenPriceMerkleMintModule is
    MerkleList,
    NativePrice,
    MinterTracker,
    ERC165CheckerERC721Collective,
    TokenRecoverable
{
    event CollectiveTokenMinted(
        address indexed collective,
        address indexed account,
        uint256 indexed amount
    );

    constructor(address admin) TokenRecoverable(admin) {}

    /// Enforce that a requested mint action is allowed given the token's parameters
    /// @param collective Address of token attempting to claim
    /// @param merkleProof List of hashes to traverse merkle tree to prove airdrop
    /// @param amount Number of collective tokens to mint
    function mint(
        address collective,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) external payable onlyCollectiveInterface(collective) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        verifyProof(collective, merkleProof, leaf);

        collectNativePrice(collective, amount);
        checkMintMax(collective, amount);

        IERC721Collective(collective).bulkMintToOneAddress(msg.sender, amount);

        emit CollectiveTokenMinted(collective, msg.sender, amount);
    }

    /// This function is called for all messages sent to this contract (there
    /// are no other functions). Sending NativeToken to this contract will cause an
    /// exception, because the fallback function does not have the `payable`
    /// modifier.
    /// Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
    fallback() external {
        revert("NativePriceMerkleMintModule: non-existent function");
    }
}