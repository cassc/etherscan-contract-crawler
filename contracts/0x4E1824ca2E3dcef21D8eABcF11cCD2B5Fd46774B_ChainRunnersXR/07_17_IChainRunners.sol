// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../core/ChainRunnersTypes.sol";

interface IChainRunners is IERC721Enumerable {
    function getDna(uint256 _tokenId) external view returns (uint256);
}