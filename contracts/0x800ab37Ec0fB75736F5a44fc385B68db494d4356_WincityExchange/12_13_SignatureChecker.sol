// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 *  __          _______ _   _  _____ _____ _________     __
 *  \ \        / /_   _| \ | |/ ____|_   _|__   __\ \   / /
 *   \ \  /\  / /  | | |  \| | |      | |    | |   \ \_/ /
 *    \ \/  \/ /   | | | . ` | |      | |    | |    \   /
 *     \  /\  /   _| |_| |\  | |____ _| |_   | |     | |
 *      \/  \/   |_____|_| \_|\_____|_____|  |_|     |_|
 *
 * @author Wincity | Antoine Duez
 * @title SignatureChecker
 * @notice This library allows verification of signatures.
 */
library SignatureChecker {
    uint256 private constant HALF_CURVE_ORDER =
        uint256(
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        );

    // keccak256("isValidSignature(bytes32,bytes")
    // bytes4 private constant INTERFACE_ID_ERC1271 = bytes4(0x1626ba7e);

    /**
     * @notice Recovers the signer of a signature (for EOA)
     * @param hash the hash containing the signed message
     * @param v parameter (27 or 28). This prevents maleability since the public key recovery equation has two possible solutions.
     * @param r parameter
     * @param s parameter
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <= HALF_CURVE_ORDER,
            "Signature: Invalid s parameter"
        );
        require(v == 27 || v == 28, "Signature: Invalid v parameter");

        address signer = ecrecover(hash, v, r, s);

        require(signer != address(0), "Signature: Invalid signer");

        return signer;
    }

    /**
     * @notice Returns whether the signer matches the signed message
     * @param hash the hash containing the signed message
     * @param signer the signer address to confirm message validity
     * @param v parameter (27 or 28)
     * @param r parameter
     * @param s parameter
     * @param domainSeparator parameter to prevent signature being executed in other chains and environments
     * @return bool true if valid, false if not
     */
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );

        if (Address.isContract(signer)) {
            return false;
        }

        return recover(digest, v, r, s) == signer;
    }
}