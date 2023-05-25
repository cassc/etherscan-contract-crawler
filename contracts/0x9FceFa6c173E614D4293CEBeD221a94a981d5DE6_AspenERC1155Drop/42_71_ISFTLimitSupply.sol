// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRestrictedSFTLimitSupplyV0 {
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external;
}

interface IRestrictedSFTLimitSupplyV1 is IRestrictedSFTLimitSupplyV0 {
    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);
}