// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {

    //
    // function recover
    //  @Description:  Recover signer from the signature
    //  @param bytes32  hash  Including has of signiture information
    //  @param uint8 Two possibilities, to enforce decryption from multiple angles using public key
    //  @param bytes32
    //  @param bytes32
    //  @return internal
    //
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            " Invalid s parameter"
        );

        require(v == 27 || v == 28, "Invalid v parameter");

        // Recover one signing address if signature is normal
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), " Invalid signer");

        return signer;
    }
    
    //
    // tion verify
    //  @Description: To verify of signer matches all the signature information
    //  @param bytes32
    //  @param address
    //  @param uint8
    //  @param bytes32
    //  @param bytes32
    //  @param bytes32
    //  @return internal
    //
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        // \x19\x01 Standard prefix code
        // https://eips.ethereum.org/EIPS/eip-712#specification
        // Checking code of the input domain and hash
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        // If the signature address is the contract address
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId(see IERC1271) of signing contract
            // Standard 1271 API
            return IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
        } else {
            // Check if signature address is same as input address
            return recover(digest, v, r, s) == signer;
        }
    }
}