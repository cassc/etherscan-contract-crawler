// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";


interface IAINightbirds is IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}