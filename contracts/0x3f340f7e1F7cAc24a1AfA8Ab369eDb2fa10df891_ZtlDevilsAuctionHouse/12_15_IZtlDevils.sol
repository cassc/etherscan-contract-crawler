// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IZtlDevils is IERC721 {
    function mint(address target, uint tokenId) external;
    function exists(uint tokenId) external view returns (bool);
}