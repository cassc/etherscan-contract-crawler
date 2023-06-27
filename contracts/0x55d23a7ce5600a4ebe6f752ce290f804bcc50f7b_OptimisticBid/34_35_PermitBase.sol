// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../constants/Permit.sol";

/// @title PermitBase
/// @author Tessera
/// @notice Utility contract for computing permit signature approvals for FERC1155 tokens
abstract contract PermitBase {
    /// @notice Mapping of token owner to nonce value
    mapping(address => uint256) public nonces;

    /// @dev Computes hash of permit struct
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    function _computePermitStructHash(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline
    ) internal returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    _owner,
                    _operator,
                    _id,
                    _approved,
                    nonces[_owner]++,
                    _deadline
                )
            );
    }

    /// @dev Computes hash of permit all struct
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    function _computePermitAllStructHash(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline
    ) internal returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_ALL_TYPEHASH,
                    _owner,
                    _operator,
                    _approved,
                    nonces[_owner]++,
                    _deadline
                )
            );
    }

    /// @dev Computes domain separator to prevent signature collisions
    /// @return Hash of the contract-specific fields
    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(NAME)),
                    keccak256(bytes(VERSION)),
                    block.chainid,
                    address(this)
                )
            );
    }

    /// @dev Computes digest of domain separator and struct hash
    /// @param _domainSeparator Hash of contract-specific fields
    /// @param _structHash Hash of signature fields struct
    /// @return Hash of the signature digest
    function _computeDigest(bytes32 _domainSeparator, bytes32 _structHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator, _structHash));
    }
}