// SPDX-License-Identifier: GPL-3.0
/********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░██████████████████████░░░ *
 * ░░░██░░░░░░██░░░░░░████░░░░░ *
 * ░░░██░░░░░░██░░░░░░██░░░░░░░ *
 * ░░░██████████████████░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 ************************♥tt****/
pragma solidity ^0.8.15;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IPhunksToken is IERC721 {

    function getPhunksBelongingToOwner(address _owner) external view returns (uint256[] memory);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

}