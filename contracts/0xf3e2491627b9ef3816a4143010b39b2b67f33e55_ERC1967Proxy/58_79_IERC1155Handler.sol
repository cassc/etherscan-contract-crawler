// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC1155Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC1155 function
     */
    event DepositedERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc1155 deposit
     * @param token the address of deposited tokens
     * @param tokenId the id of deposited tokens
     * @param amount the amount of deposited tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - tokens will burned, false - tokens will transferred
     */
    struct DepositERC1155Parameters {
        address token;
        uint256 tokenId;
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc1155 withdrawal
     * @param token the address of withdrawal tokens
     * @param tokenId the id of withdrawal tokens
     * @param tokenURI the uri of withdrawal tokens
     * @param amount the amount of withdrawal tokens
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC1155Parameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc1155 tokens
     * @param params_ the parameters for the erc1155 deposit
     */
    function depositERC1155(DepositERC1155Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc1155 tokens
     * @param params_ the parameters for the erc1155 withdrawal
     */
    function withdrawERC1155(WithdrawERC1155Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc1155 tokens with bundle
     * @param params_ the parameters for the erc1155 withdrawal
     */
    function withdrawERC1155Bundle(WithdrawERC1155Parameters memory params_) external;
}