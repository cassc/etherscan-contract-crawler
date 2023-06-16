// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';

contract SignatureValidation is EIP712Upgradeable {
    mapping(bytes32 => bool) private _gluwaNoncesUsed;

    /// @notice Validates the signature of the given hash.
    /// @param hash The hash to be validated.
    /// @param gluwaNonce The gluwaNonce of the signature.
    /// @param v The recovery id of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function validateSignature(bytes32 hash, uint96 gluwaNonce, uint8 v, bytes32 r, bytes32 s) internal returns (address) {
        // Return the signer address if the signature is valid
        address signer = ecrecover(_hashTypedDataV4(hash), v, r, s);

        // Check if the gluwaNonce has been used already
        require(!isNonceUsed(gluwaNonce, signer), 'SignatureValidation: gluwaNonce already used');

        _setNonceUsed(gluwaNonce, signer);

        return signer;
    }

    /// @notice Checks if the given gluwaNonce has been used by the given address.
    /// @param gluwaNonce The gluwaNonce to be checked.
    /// @param account The address to be checked.
    /// @return True if the gluwaNonce has been used, false otherwise.
    function isNonceUsed(uint96 gluwaNonce, address account) public view returns (bool) {
        return _gluwaNoncesUsed[keccak256(abi.encodePacked(account, gluwaNonce))];
    }

    /// @notice Set gluwaNonce as used to prevent a signature to be used
    /// @param gluwaNonce The gluwaNonce to be checked.
    function setNonceUsed(uint96 gluwaNonce) external {
        return _setNonceUsed(gluwaNonce, msg.sender);
    }

    /// @notice Set gluwaNonce as used to prevent a signature to be used (private)
    /// @param gluwaNonce The gluwaNonce to be checked.
    function _setNonceUsed(uint96 gluwaNonce, address account) private {
        _gluwaNoncesUsed[keccak256(abi.encodePacked(account, gluwaNonce))] = true;
    }

    uint256[50] private __gap;
}