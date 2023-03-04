// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "ERC721A/extensions/IERC721AQueryable.sol";

interface IHoneyComb is IERC721AQueryable {
    function mint(address to) external returns (uint256);

    function batchMint(address to, uint256 amount) external;

    function burn(uint256 _id) external;

    function nextTokenId() external view returns (uint256);
}