// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../handlers/IERC20Handler.sol";
import "../handlers/IERC721Handler.sol";
import "../handlers/ISBTHandler.sol";
import "../handlers/IERC1155Handler.sol";
import "../handlers/INativeHandler.sol";
import "../utils/ISigners.sol";

/**
 * @notice The Bridge contract
 *
 * The Bridge contract acts as a permissioned way of transferring assets (ERC20, ERC721, ERC1155, Native) between
 * 2 different blockchains.
 *
 * In order to correctly use the Bridge, one has to deploy both instances of the contract on the base chain and the
 * destination chain, as well as setup a trusted backend that will act as a `signer`.
 *
 * Each Bridge contract can either give or take the user assets when they want to transfer tokens. Both liquidity pool
 * and mint-and-burn way of transferring assets are supported.
 *
 * The bridge enables the transaction bundling feature as well.
 */
interface IBridge is
    IBundler,
    ISigners,
    IERC20Handler,
    IERC721Handler,
    ISBTHandler,
    IERC1155Handler,
    INativeHandler
{
    /**
     * @notice the enum that helps distinguish functions for calling within the signature
     * @param None the special zero type, method types start from 1
     * @param AuthorizeUpgrade the type corresponding to the _authorizeUpgrade function
     * @param ChangeBundleExecutorImplementation the type corresponding to the changeBundleExecutorImplementation function
     * @param ChangeFacade the type corresponding to the changeFacade function
     */
    enum MethodId {
        None,
        AuthorizeUpgrade,
        ChangeBundleExecutorImplementation,
        ChangeFacade
    }

    /**
     * @notice the function to verify merkle leaf
     * @param tokenDataLeaf_ the abi encoded token parameters
     * @param bundle_ the encoded transaction bundle with encoded salt
     * @param originHash_ the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver_ the address who will receive tokens
     * @param proof_ the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    function verifyMerkleLeaf(
        bytes memory tokenDataLeaf_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_
    ) external;
}