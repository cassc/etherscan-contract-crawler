// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

library RenVMHashes {
    /// @notice calculateSelectorHash calculates and hashes the selector hash,
    ///         which is formatted as `ASSET/toCHAIN`.
    function calculateSelectorHash(string memory assetSymbol, string memory chain) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(assetSymbol, "/to", chain));
    }

    /// @notice calculateSigHash hashes the parameters to reconstruct the data
    ///         signed by RenVM.
    function calculateSigHash(
        bytes32 pHash,
        uint256 amount,
        bytes32 selectorHash,
        address to,
        bytes32 nHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(pHash, amount, selectorHash, to, nHash));
    }
}