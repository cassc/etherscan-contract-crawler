// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEIP712Signable} from "../interfaces/utils/IEIP712Signable.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title EIP-712 Signable Contract
abstract contract EIP712Signable is IEIP712Signable {

    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /// @notice Gets whether an address is an authorized signer.
    mapping(address => bool) public signers;

    constructor() {
        _CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    function _NAME() virtual internal pure returns (string memory);

    function _VERSION() virtual internal pure returns (string memory);

    /// @inheritdoc IEIP712Signable
    function EIP712Data() external view 
        returns (
            string memory name,
            string memory version,
            address verifyingContract,
            bytes32 domainSeparator
        )
    {
        name = _NAME();
        version = _VERSION();
        verifyingContract = address(this);
        domainSeparator = _buildDomainSeparator();
    }

    function _deriveEIP712Digest(bytes32 hash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparator(), hash);
    }

    function _verifySignature(bytes memory signature, bytes32 digest, address signer) internal {
        address signatory = ECDSA.recover(digest, signature);
        if (signatory == address(0) || signatory != signer) {
            revert SignatureInvalid();
        }
    }

    function _verifySignature(bytes memory signature, bytes32 digest) internal view {
        address signatory = ECDSA.recover(digest, signature);
        if (signatory == address(0) || !signers[signatory]) {
            revert SignatureInvalid();
        }
    }

    /// @dev Generates an EIP-712 domain separator.
    /// @return A 256-bit domain separator tied to this contract.
    function _buildDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_NAME())),
                keccak256(bytes(_VERSION())),
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev Returns the domain separator tied to the contract.
    /// @return 256-bit domain separator tied to this contract.
    function _domainSeparator() internal view returns (bytes32) {
        if (block.chainid == _CHAIN_ID) {
            return _DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

}