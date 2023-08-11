// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev ERC1167 proxy is known bytecode that wraps the implementation address.
/// This is the prefix.
bytes constant ERC1167_PREFIX = hex"363d3d373d3d3d363d73";
/// @dev ERC1167 proxy is known bytecode that wraps the implementation address.
/// This is the suffix.
bytes constant ERC1167_SUFFIX = hex"5af43d82803e903d91602b57fd5bf3";
/// @dev We can more efficiently compare equality of hashes of regions of memory
/// than the regions themselves.
/// This is the hash of the ERC1167 proxy prefix.
bytes32 constant ERC1167_PREFIX_HASH = keccak256(ERC1167_PREFIX);
/// @dev We can more efficiently compare equality of hashes of regions of memory
/// than the regions themselves.
/// This is the hash of the ERC1167 proxy suffix.
bytes32 constant ERC1167_SUFFIX_HASH = keccak256(ERC1167_SUFFIX);
/// @dev The bounds of the ERC1167 proxy prefix are constant.
/// This is the start offset of the ERC1167 proxy prefix.
uint256 constant ERC1167_PREFIX_START = 0x20;
/// @dev The bounds of the ERC1167 proxy suffix are constant.
/// This is the start offset of the ERC1167 proxy suffix.
uint256 constant ERC1167_SUFFIX_START = 0x20 + ERC1167_PROXY_LENGTH - ERC1167_SUFFIX_LENGTH;
/// @dev The ERC1167 proxy prefix is a known length.
uint256 constant ERC1167_PREFIX_LENGTH = 10;
/// @dev The ERC1167 proxy suffix is a known length.
uint256 constant ERC1167_SUFFIX_LENGTH = 15;
/// @dev The length of a proxy contract is constant as the implementation
/// address is always 20 bytes.
uint256 constant ERC1167_PROXY_LENGTH = 20 + ERC1167_PREFIX_LENGTH + ERC1167_SUFFIX_LENGTH;
/// @dev The implementation address read offset is constant.
uint256 constant ERC1167_IMPLEMENTATION_ADDRESS_OFFSET = ERC1167_PREFIX_LENGTH + 20;

/// @title LibExtrospectERC1167Proxy
library LibExtrospectERC1167Proxy {
    /// @notice Checks if the given bytecode is an ERC1167 proxy. If so,
    /// returns the implementation address.
    /// @param bytecode The bytecode to check.
    /// @return result True if the bytecode is an ERC1167 proxy.
    /// @return implementationAddress The address of the implementation contract.
    /// This is only valid if `result` is true, else it is zero.
    function isERC1167Proxy(bytes memory bytecode) internal pure returns (bool result, address implementationAddress) {
        unchecked {
            {
                // The bytecode must be the correct length. As the majority of
                // accounts onchain are EOAs or contracts that are not ERC1167
                // proxies, this is a cheap check to perform first and return
                // early if it fails.
                if (bytecode.length != ERC1167_PROXY_LENGTH) {
                    return (false, address(0));
                } else {
                    // Assume the bytecode is an ERC1167 proxy. If any of the
                    // checks fail, this will be set to false.
                    result = true;
                }
            }

            // The bytecode must start with the prefix.
            uint256 prefixStart = ERC1167_PREFIX_START;
            uint256 prefixLength = ERC1167_PREFIX_LENGTH;
            bytes32 prefixHash = ERC1167_PREFIX_HASH;
            assembly ("memory-safe") {
                result := and(result, eq(keccak256(add(bytecode, prefixStart), prefixLength), prefixHash))
            }

            {
                // The bytecode must end with the suffix.
                uint256 suffixStart = ERC1167_SUFFIX_START;
                uint256 suffixLength = ERC1167_SUFFIX_LENGTH;
                bytes32 suffixHash = ERC1167_SUFFIX_HASH;
                assembly ("memory-safe") {
                    result := and(result, eq(keccak256(add(bytecode, suffixStart), suffixLength), suffixHash))
                }
            }

            {
                if (result) {
                    // If the bytecode is an ERC1167 proxy, extract the
                    // implementation address.
                    uint256 implementationAddressOffset = ERC1167_IMPLEMENTATION_ADDRESS_OFFSET;
                    uint256 implementationAddressMask = type(uint160).max;
                    assembly ("memory-safe") {
                        implementationAddress :=
                            and(mload(add(bytecode, implementationAddressOffset)), implementationAddressMask)
                    }
                }
            }
        }
    }
}