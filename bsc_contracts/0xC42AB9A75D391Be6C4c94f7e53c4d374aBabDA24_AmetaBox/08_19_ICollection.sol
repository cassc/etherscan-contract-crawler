// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICollection is IERC721Enumerable {
    function mint(address _to) external returns (uint256);

    function mintBatch(address _to, uint256 _qty)
        external
        returns (uint256[] memory tokenIds);

    function tokenIdsOfOwner(address _owner)
        external
        view
        returns (uint256[] memory tokenIds);
}