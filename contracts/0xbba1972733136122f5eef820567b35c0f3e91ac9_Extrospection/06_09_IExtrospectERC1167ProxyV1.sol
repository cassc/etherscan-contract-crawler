// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title IExtrospectERC1167ProxyV1
/// @notice External functions for offchain processing to determine if any given
/// address is an ERC1167 proxy and if so, what the implementation address is.
/// ERC1167 proxies are a known bytecode so there is no possibility of a false
/// positive outside of a bug in the implementation of this interface.
/// https://eips.ethereum.org/EIPS/eip-1167
interface IExtrospectERC1167ProxyV1 {
    /// Checks if the given address is an ERC1167 proxy. The caller MUST check
    /// the result is true before using the implementation address, otherwise
    /// a valid proxy to `address(0)` and an invalid proxy will be
    /// indistinguishable.
    ///
    /// @param account The address to check.
    /// @return result True if the address is an ERC1167 proxy.
    /// @return implementationAddress The address of the implementation contract.
    /// This is only valid if `result` is true, else it is zero.
    function isERC1167Proxy(address account) external view returns (bool result, address implementationAddress);
}