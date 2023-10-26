// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IboInterface is IERC721Enumerable {
    function totalCvgPerToken(uint256 tokenId) external view returns (uint256);

    function iboStartTimestamp() external view returns (uint256);

    function getTokenIdsForWallet(address _wallet) external view returns (uint256[] memory);
}