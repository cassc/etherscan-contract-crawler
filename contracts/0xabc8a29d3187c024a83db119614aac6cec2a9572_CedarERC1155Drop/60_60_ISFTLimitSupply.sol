// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRestrictedSFTLimitSupplyV0 {
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external;
}