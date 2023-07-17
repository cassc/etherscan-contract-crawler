// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRatioAdapter {

    // --- Events ---
    event TokenSet(address token, uint8 approach);
    event RatioProviderSet(address token, address provider);

    // --- Functions ---
    function fromValue(address token, uint256 amount) external view returns (uint256);
    function toValue(address token, uint256 amount) external view returns (uint256);
}