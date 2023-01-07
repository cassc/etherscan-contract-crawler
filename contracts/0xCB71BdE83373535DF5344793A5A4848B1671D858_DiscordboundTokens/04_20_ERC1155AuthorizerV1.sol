// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 *
 * _______/\\\\\_______/\\\\\\\\\\\\\____/\\\\\\\\\\\\\\\__/\\\\\_____/\\\_____/\\\\\\\\\\__
 *  _____/\\\///\\\____\/\\\/////////\\\_\/\\\///////////__\/\\\\\\___\/\\\___/\\\///////\\\_
 *   ___/\\\/__\///\\\__\/\\\_______\/\\\_\/\\\_____________\/\\\/\\\__\/\\\__\///______/\\\__
 *    __/\\\______\//\\\_\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\_____\/\\\//\\\_\/\\\_________/\\\//___
 *     _\/\\\_______\/\\\_\/\\\/////////____\/\\\///////______\/\\\\//\\\\/\\\________\////\\\__
 *      _\//\\\______/\\\__\/\\\_____________\/\\\_____________\/\\\_\//\\\/\\\___________\//\\\_
 *       __\///\\\__/\\\____\/\\\_____________\/\\\_____________\/\\\__\//\\\\\\__/\\\______/\\\__
 *        ____\///\\\\\/_____\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\___\//\\\\\_\///\\\\\\\\\/___
 *         ______\/////_______\///______________\///////////////__\///_____\/////____\/////////_____
 *          AUTHORIZER_______________________________________________________________________________
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ERC1155AuthorizerV1 is Ownable {
    address private authorizerAddress;

    constructor(address authorizerAddress_) {
        authorizerAddress = authorizerAddress_;
    }

    /**
     * @dev Requires ECFSA recovery of a sender, nonce, tokenId, and signature
     */
    function requireRecovery(
        address sender,
        uint256 nonce_,
        uint256 tokenId_,
        bytes memory signature_
    ) internal view {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce_, tokenId_));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);

        require(
            ECDSA.recover(message, signature_) == authorizerAddress,
            "Bad signature"
        );
    }

    /**
     * @dev The address of the authorizer.
     */
    function authorizer() public view returns (address) {
        return authorizerAddress;
    }

    /**
     * @dev Sets the address of the authorizer.
     */
    function setAuthorizerAddress(address address_) external onlyOwner {
        authorizerAddress = address_;
    }
}