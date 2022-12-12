// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/IBaseNFT.sol";

interface IMintNFT is IBaseNFT {
    function mint(address to) external returns (uint256 tokenId);
}