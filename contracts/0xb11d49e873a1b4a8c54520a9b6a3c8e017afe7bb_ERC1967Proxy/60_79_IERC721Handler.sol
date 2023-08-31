// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC721Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC721 function
     */
    event DepositedERC721(
        address token,
        uint256 tokenId,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc721 deposit
     * @param token the address of the deposited token
     * @param tokenId the id of deposited token
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - token will burned, false - token will transferred
     */
    struct DepositERC721Parameters {
        address token;
        uint256 tokenId;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc721 withdrawal
     * @param token the address of the withdrawal token
     * @param tokenId the id of the withdrawal token
     * @param tokenURI the uri of the withdrawal token
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC721Parameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc721 tokens
     * @param params_ the parameters for the erc721 deposit
     */
    function depositERC721(DepositERC721Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc721 tokens
     * @param params_ the parameters for the erc721 withdrawal
     */
    function withdrawERC721(WithdrawERC721Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc721 tokens with bundle
     * @param params_ the parameters for the erc721 withdrawal
     */
    function withdrawERC721Bundle(WithdrawERC721Parameters memory params_) external;
}