// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface INativeHandler is IBundler {
    /**
     * @notice the event emitted from the depositNative function
     */
    event DepositedNative(
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver
    );

    /**
     * @notice the struct that represents parameters for the native deposit
     * @param amount the amount of deposited native tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     */
    struct DepositNativeParameters {
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
    }

    /**
     * @notice the struct that represents parameters for the native withdrawal
     * @param amount the amount of withdrawal native funds
     * @param bundle the encoded transaction bundle
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    struct WithdrawNativeParameters {
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
    }

    /**
     * @notice the function to deposit native tokens
     * @param params_ the parameters for the native deposit
     */
    function depositNative(DepositNativeParameters calldata params_) external payable;

    /**
     * @notice the function to withdraw native tokens
     * @param params_ the parameters for the native withdrawal
     */
    function withdrawNative(WithdrawNativeParameters memory params_) external;

    /**
     * @notice the function to withdraw native tokens with bundle
     * @param params_ the parameters for the native withdrawal
     */
    function withdrawNativeBundle(WithdrawNativeParameters memory params_) external;
}