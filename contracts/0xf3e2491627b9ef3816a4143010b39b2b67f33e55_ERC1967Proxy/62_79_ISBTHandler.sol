// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface ISBTHandler is IBundler {
    /**
     * @notice the event emitted from the depositSBT function
     */
    event DepositedSBT(
        address token,
        uint256 tokenId,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver
    );

    /**
     * @notice the struct that represents parameters for the sbt deposit
     * @param token the address of deposited token
     * @param tokenId the id of deposited token
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     */
    struct DepositSBTParameters {
        address token;
        uint256 tokenId;
        IBundler.Bundle bundle;
        string network;
        string receiver;
    }

    /**
     * @notice the struct that represents parameters for the sbt withdrawal
     * @param token the address of the withdrawal token
     * @param tokenId the id of the withdrawal token
     * @param tokenURI the uri of the withdrawal token
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    struct WithdrawSBTParameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
    }

    /**
     * @notice the function to deposit sbt tokens
     * @param params_ the parameters for the sbt deposit
     */
    function depositSBT(DepositSBTParameters calldata params_) external;

    /**
     * @notice the function to withdraw sbt tokens
     * @param params_ the parameters for the sbt withdrawal
     */
    function withdrawSBT(WithdrawSBTParameters memory params_) external;

    /**
     * @notice the function to withdraw sbt tokens with bundle
     * @param params_ the parameters for the sbt withdrawal
     */
    function withdrawSBTBundle(WithdrawSBTParameters memory params_) external;
}