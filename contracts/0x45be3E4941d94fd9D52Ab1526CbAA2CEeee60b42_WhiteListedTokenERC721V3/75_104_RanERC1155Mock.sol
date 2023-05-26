// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract RanERC1155Mock is ERC1155 {
    constructor (string memory uri) ERC1155 (uri) public {}

    function mint(address account, uint256 id, uint256 amount) public {
        _mint(account, id, amount, '');
    }
}