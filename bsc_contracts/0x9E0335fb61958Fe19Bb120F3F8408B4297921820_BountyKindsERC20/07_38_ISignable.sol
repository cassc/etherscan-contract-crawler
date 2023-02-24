// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISignable {
    error Signable__InvalidSignature();

    event NonceIncremented(
        address indexed operator,
        bytes32 indexed id,
        uint256 indexed value
    );

    /**
     * @dev Returns the domain separator for EIP712 v4
     * @return Domain separator for EIP712 v4
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}