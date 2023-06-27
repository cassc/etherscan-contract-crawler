// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@rmrk-team/evm-contracts/contracts/RMRK/multiasset/IERC5773.sol";

interface IRMRKExtended is IERC5773 {
    /**
     * @notice EXTENDED functions not available in the standard RMRK MultiResource interface
     */

    function addAssetEntry(
        string memory metadataURI
    ) external returns (uint256);

    function addAssetToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 replacesAssetWithId
    ) external;

    function mint(
        address to,
        uint256 numToMint
    ) external payable returns (uint256);

    function nestMint(
        address to,
        uint256 numToMint,
        uint256 destinationId
    ) external payable returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;
}