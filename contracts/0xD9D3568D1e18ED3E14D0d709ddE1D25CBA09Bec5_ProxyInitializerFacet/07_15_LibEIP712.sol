//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageAnticDomain} from "../storage/StorageAnticDomain.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712 {
    bytes32 internal constant _DOMAIN_NAME = keccak256("Antic");
    bytes32 internal constant _DOMAIN_VERSION = keccak256("1");
    bytes32 internal constant _SALT = keccak256("Magrathea");

    bytes32 internal constant _EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    /// @dev Initializes the EIP712's domain separator
    /// note Must be called at least once, because it saves the
    /// domain separator in storage
    function _initDomainSeparator() internal {
        StorageAnticDomain.DiamondStorage storage ds = StorageAnticDomain
            .diamondStorage();

        ds.domainSeparator = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                _DOMAIN_NAME,
                _DOMAIN_VERSION,
                _chainId(),
                _verifyingContract(),
                _salt()
            )
        );
    }

    function _toTypedDataHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparator(), messageHash);
    }

    function _domainSeparator() internal view returns (bytes32) {
        StorageAnticDomain.DiamondStorage storage ds = StorageAnticDomain
            .diamondStorage();

        return ds.domainSeparator;
    }

    function _chainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function _verifyingContract() internal view returns (address) {
        return address(this);
    }

    function _salt() internal pure returns (bytes32) {
        return _SALT;
    }
}