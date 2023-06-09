// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IBlockverse is IERC721Enumerable {
    function mint(uint256 amount, bool autoStake) external payable;
    function whitelistMint(uint256 amount, bytes32[] memory proof, bool autoStake) external payable;
    function walletOfUser(address user) external view returns (uint256[] memory);
    function getTokenFaction(uint256 tokenId) external view returns (BlockverseFaction);

    enum BlockverseFaction {
        UNASSIGNED,
        APES,
        KONGS,
        DOODLERS,
        CATS,
        KAIJUS,
        ALIENS
    }
}