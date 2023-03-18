// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

library LibEIP712 {
    // Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    // Note that we use the verifying contract's proxy address here instead of the verifying contract's address,
    // so that users signatures remain valid when we upgrade the ERC20Token contract
    function hashEIP712Message(bytes32 hashStruct, address verifyingContractProxy)
        internal
        pure
        returns (bytes32 result)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                ),
                keccak256(bytes('Energi')),
                keccak256(bytes('1')),
                chainId,
                verifyingContractProxy
            )
        );

        result = keccak256(abi.encodePacked('\x19\x01', eip712DomainHash, hashStruct));
    }
}