// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IScientists is IERC721 {
    function getRandomPaidScientistOwner(uint256) external returns (address);
    function increasePool(uint256) external;
}