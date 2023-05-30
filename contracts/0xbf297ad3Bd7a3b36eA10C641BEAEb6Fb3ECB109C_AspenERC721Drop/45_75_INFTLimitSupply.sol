// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRestrictedNFTLimitSupplyV0 {
    function setMaxTotalSupply(uint256 _maxTotalSupply) external;
}

interface IRestrictedNFTLimitSupplyV1 is IRestrictedNFTLimitSupplyV0 {
    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);
}