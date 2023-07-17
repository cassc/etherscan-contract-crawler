// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILockERC721 is IERC721 {
    function lockId(uint256 _id) external;

    function unlockId(uint256 _id) external;

    function freeId(uint256 _id, address _contract) external;

    function keepTOLTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}