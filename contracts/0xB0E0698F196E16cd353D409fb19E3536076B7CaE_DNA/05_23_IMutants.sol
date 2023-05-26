//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMutants is IERC721 {
    function MAX_SUPPLY() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function tier(uint256) external view returns (uint256);
}