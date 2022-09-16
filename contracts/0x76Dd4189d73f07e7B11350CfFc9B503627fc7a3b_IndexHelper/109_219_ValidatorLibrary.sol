// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title Validator library
/// @notice Library containing set of utilities related to Phuture job validation
library ValidatorLibrary {
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        address signer;
        uint deadline;
    }

    /// @notice Verifies if the given `_data` object was signed by proper signer
    /// @param self Sign object reference
    /// @param _data Data object to verify signature
    function verify(
        Sign calldata self,
        bytes memory _data,
        uint _nonce
    ) internal view returns (bool) {
        require(block.timestamp <= self.deadline, "ValidatorLibrary: EXPIRED");

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,uint256 nonce,uint256 deadline)"
                ),
                keccak256(bytes("PhutureJob")),
                keccak256(bytes("1")),
                block.chainid,
                address(this),
                _nonce,
                self.deadline
            )
        );

        return
            self.signer ==
            ecrecover(
                keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, keccak256(_data))),
                self.v,
                self.r,
                self.s
            );
    }
}