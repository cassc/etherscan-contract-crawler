//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/Enums.sol";

abstract contract HoneyCombsDeluxeI is Ownable, IERC1155 {
    function burn(
        address _owner,
        uint256 _rarity,
        uint256 _amount
    ) external virtual;
}