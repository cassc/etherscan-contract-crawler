// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title: Murakami.Flowers Seed
/// @author: niftykit.com

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMurakamiFlowersSeed is IERC1155 {
    function burn(address account, uint256 amount) external;
}