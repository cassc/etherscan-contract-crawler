// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract EIP712 {
    using ECDSA for bytes32;
    bytes32 public DOMAIN_SEPARATOR;

    function _init(string memory name, string memory version) internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    function _hashTypedDataV4(bytes32 hashStruct)
        internal
        view
        returns (bytes32 digest)
    {
        digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );
    }

    function _verify(
        address owner,
        bytes calldata signature,
        bytes32 hashStruct
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(hashStruct);
        address recoveredAddress = digest.recover(signature);
        return (recoveredAddress == owner);
    }
}