// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

interface IGardenValuer {
    function calculateGardenValuation(address _garden, address _quoteAsset) external view returns (uint256);

    function getLossesGarden(address _garden, uint256 _since) external view returns (uint256);
}