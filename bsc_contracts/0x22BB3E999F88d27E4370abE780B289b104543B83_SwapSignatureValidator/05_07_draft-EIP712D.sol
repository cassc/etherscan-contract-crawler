// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

/**
 * @dev xSwap fork of the original OpenZeppelin's {EIP712} implementation
 *
 * The fork allows typed data hashing with arbitrary chainId & verifyingContract for domain separator
 */

pragma solidity ^0.8.16;

import "./ECDSA.sol";

abstract contract EIP712D {
    /* solhint-disable var-name-mixedcase */

    // bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private immutable _NAME_HASH;
    bytes32 private immutable _VERSION_HASH;

    /* solhint-enable var-name-mixedcase */

    constructor(string memory name, string memory version) {
        _NAME_HASH = keccak256(bytes(name));
        _VERSION_HASH = keccak256(bytes(version));
    }

    function _domainSeparatorV4D(uint256 chainId, address verifyingContract) internal view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _NAME_HASH, _VERSION_HASH, chainId, verifyingContract));
    }

    function _hashTypedDataV4D(
        bytes32 structHash,
        uint256 chainId,
        address verifyingContract
    ) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4D(chainId, verifyingContract), structHash);
    }
}