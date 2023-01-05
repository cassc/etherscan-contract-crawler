// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICollection is IERC721 {
    function totalSupply() external view returns (uint256);
}