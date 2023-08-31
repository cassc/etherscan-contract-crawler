// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC20Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC20 function
     */
    event DepositedERC20(
        address token,
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc20 deposit
     * @param token the address of the deposited token
     * @param amount the amount of deposited tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - tokens will burned, false - tokens will transferred
     */
    struct DepositERC20Parameters {
        address token;
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc20 withdrawal
     * @param token the address of the withdrawal token
     * @param amount the amount of withdrawal tokens
     * @param bundle the encoded transaction bundle with encoded salt
     * @param receiver the address who will receive tokens
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC20Parameters {
        address token;
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc20 tokens
     * @param params_ the parameters for the erc20 deposit
     */
    function depositERC20(DepositERC20Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc20 tokens
     * @param params_ the parameters for the erc20 withdrawal
     */
    function withdrawERC20(WithdrawERC20Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc20 tokens with bundle
     * @param params_ the parameters for the erc20 withdrawal
     */
    function withdrawERC20Bundle(WithdrawERC20Parameters memory params_) external;
}