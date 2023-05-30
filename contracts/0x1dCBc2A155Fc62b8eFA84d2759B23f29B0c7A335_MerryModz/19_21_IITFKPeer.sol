// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// A simple interface
interface IITFKPeer {
    function addFreeMintableContracts(address[] memory _contracts) external;

    function getFreeMintsRemaining(uint256 _tokenId)
        external
        view
        returns (uint8);

    function updateFreeMintAllocation(uint256 _tokenId) external;

    function getFoundersKeysByTierIds(address _wallet, uint8 _includeTier)
        external
        view
        returns (uint256[] memory fks);
}