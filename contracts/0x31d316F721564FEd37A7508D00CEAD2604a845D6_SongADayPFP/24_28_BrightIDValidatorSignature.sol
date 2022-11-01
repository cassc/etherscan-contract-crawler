// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./../validator/BrightIDValidatorSingle.sol";

/**
 * @dev Signature based implementation of {BrightIDValidatorSingle}.
 */
contract BrightIDValidatorSignature is BrightIDValidatorSingle {
    using ECDSA for bytes32;

    bytes private _soulboundMessage;

    constructor(
        address verifier_,
        bytes32 context_,
        bytes memory soulboundMessage_
    ) BrightIDValidatorSingle(verifier_, context_) {
        _soulboundMessage = soulboundMessage_;
    }

    /**
     * @dev Returns the soulbound message.
     */
    function soulboundMessage() public view virtual returns (string memory) {
        return string(_soulboundMessage);
    }

    /**
     * @dev Validate signed BrightID verification data.
     *
     * Requirements:
     *
     * - signer of signature must be a trusted validator.
     */
    function _validate(
        address[] calldata contextIds,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        bytes32 message = keccak256(abi.encodePacked(context(), contextIds, timestamp));
        address signer = message.recover(v, r, s);
        require(isTrustedValidator(signer), "BrightIDValidatorSignature: Signer not authorized");
    }
}