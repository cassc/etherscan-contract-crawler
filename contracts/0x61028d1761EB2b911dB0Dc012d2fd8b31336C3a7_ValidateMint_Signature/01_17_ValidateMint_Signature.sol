// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { Ownable } from "@boredbox-solidity-contracts/ownable/contracts/Ownable.sol";

import { IBoredBoxNFT } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";

import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { BytesLib } from "solidity-bytes-utils/contracts/BytesLib.sol";

import { IValidateMint_Signature_Functions } from "./interfaces/IValidateMint_Signature.sol";
import { AValidateMint } from "./AValidateMint.sol";

/// Reusable validation contract for checking signed authentication
/// @author S0AndS0
/// @custom:link https://boredbox.io/
contract ValidateMint_Signature is AValidateMint, IValidateMint_Signature_Functions, Ownable {
    // Mapping boxId to ECDSA public key
    // @dev See {IValidateMint_Signature_Variables-box__signer}
    mapping(uint256 => address) public box__signer;

    /// @custom:throw "Invalid signer"
    /// @custom:throw "Invalid box ID"
    constructor(
        address owner_,
        uint256 boxId,
        address signer
    ) Ownable(owner_) {
        require(signer != address(0), "Invalid signer");
        require(boxId > 0, "Invalid box ID");
        box__signer[boxId] = signer;
    }

    /// @dev See {IValidateMint_Functions-validate}
    /// @custom:throw "Invalid signer"
    /// @custom:throw "Invalid signature"
    /// @custom:throw "Auth not for you"
    /// @custom:throw "Hash mismatch"
    function validate(
        address to,
        uint256 boxId,
        uint256, /* __tokenId__ */
        bytes memory auth
    ) external view virtual override returns (uint256 validate_status) {
        require(box__signer[boxId] != address(0), "Invalid signer");

        bytes32 hash;
        assembly {
            hash := mload(add(auth, 32))
        }

        /* BytesLib.slice(bytes, start, length) */
        // 32 ⇔  length of `hash`
        // 65 ⇔  lengths of `r` + `s` + `v`
        bytes memory signature = BytesLib.slice(auth, 32, 65);

        require(SignatureChecker.isValidSignatureNow(box__signer[boxId], hash, signature), "Invalid signature");

        // 97 ⇔  length of `hash` + `signature`
        // 20 ⇔  length of `address`
        bytes memory message = BytesLib.slice(auth, 97, auth.length - 97);
        address recipient;
        assembly {
            recipient := mload(add(message, 20))
        }
        require(to == recipient, "Auth not for you");

        /// @dev Note this is so mostly hideous due to having a variable length `message`... _mostly_
        require(
            hash ==
                keccak256(
                    abi.encodePacked(
                        bytes(
                            string(
                                abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(message.length))
                            )
                        ),
                        message
                    )
                ),
            "Hash mismatch"
        );

        return VALIDATE_STATUS__PASS;
    }

    /// @dev See {IValidateMint_Signature_Functions-newBox}
    function newBox(uint256 boxId, address signer) external onlyOwner {
        require(signer != address(0), "Invalid signer");
        require(boxId > 0, "Invalid box ID");
        require(box__signer[boxId] == address(0), "Signer already assigned");
        box__signer[boxId] = signer;
    }

    /// @dev See {IValidateMint_Signature_Functions-updateKey}
    function updateKey(uint256 boxId, address signer) external onlyOwner {
        require(signer != address(0), "Invalid signer");
        require(boxId > 0, "Invalid box ID");
        require(box__signer[boxId] != address(0), "Signer did not exist");
        box__signer[boxId] = signer;
    }
}