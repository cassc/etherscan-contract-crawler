// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ArbitraryDeterministicAddress {
    function getArbitraryContractAddress(
        bytes32 _salt,
        address _factory,
        bytes32 byteCodeHash_
    ) public pure returns (address) {
        return
            address(
                uint160(
                    uint256(keccak256(abi.encodePacked(hex"ff", _factory, _salt, byteCodeHash_)))
                )
            );
    }
}