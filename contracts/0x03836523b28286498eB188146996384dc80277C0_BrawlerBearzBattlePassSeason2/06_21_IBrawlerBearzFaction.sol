//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBrawlerBearzFaction is IERC1155 {
    function getFaction(address _address) external view returns (uint256);
}