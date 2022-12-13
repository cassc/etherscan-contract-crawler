// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title RecrowTxValidatable
 * @notice Manages tx signature validation
 */
abstract contract RecrowTxValidatable is Context, EIP712 {
    using SignatureChecker for address;

    /*//////////////////////////////////////////////////////////////
                            VALIDATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if a signature is valid for a given signer and data hash.
     * @dev If signer is `_msgSender`, signature is not required.
     * @param signer The signer of the signature.
     * @param hash The data hash.
     * @param signature The signature.
     * @return bool True if validation succeed.
     * @return string The revert message if validation failed.
     */
    function _validateTx(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool, string memory) {
        if (signature.length == 0) {
            address sender = _msgSender();
            if (signer != sender) {
                return (false, "SenderMismatch");
            }
        } else {
            if (
                !signer.isValidSignatureNow(_hashTypedDataV4(hash), signature)
            ) {
                return (false, "InvalidSignature");
            }
        }
        return (true, "");
    }
}