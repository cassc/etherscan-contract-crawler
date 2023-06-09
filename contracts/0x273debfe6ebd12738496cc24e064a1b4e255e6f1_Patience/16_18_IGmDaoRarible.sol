// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IGmDaoRarible is IERC721Enumerable, IERC721Metadata {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}