// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// Local imports
import { AccessTypes } from "../structs/AccessTypes.sol";
import { LibAccessControl } from "../libraries/LibAccessControl.sol";
import { LibSignature } from "../../libraries/LibSignature.sol";

/**************************************

    Verify signature mixin

**************************************/

/// @notice Mixin that injects signature verification into facets.
library VerifySignatureMixin {
    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    error IncorrectSigner(address signer); // 0x33ffff9b

    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev Verify signature.
    /// @dev Validation: Fails if message is signed by account without signer role.
    /// @param _message Hash of message
    /// @param _v Part of signature
    /// @param _r Part of signature
    /// @param _s Part of signature
    function verifySignature(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) internal view {
        // signer of message
        address signer_ = LibSignature.recoverSigner(_message, _v, _r, _s);

        // validate signer
        if (!LibAccessControl.hasRole(AccessTypes.SIGNER_ROLE, signer_)) {
            revert IncorrectSigner(signer_);
        }
    }
}