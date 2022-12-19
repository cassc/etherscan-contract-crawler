//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev EIP712 for Antic domain.
interface IEIP712 {
    function toTypedDataHash(bytes32 messageHash)
        external
        view
        returns (bytes32);

    function domainSeparator() external view returns (bytes32);

    function chainId() external view returns (uint256 id);

    function verifyingContract() external view returns (address);

    function salt() external pure returns (bytes32);
}