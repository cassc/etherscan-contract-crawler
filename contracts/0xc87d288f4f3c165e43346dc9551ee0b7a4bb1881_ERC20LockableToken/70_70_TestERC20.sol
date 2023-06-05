// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20("FlairTest", "FTS") {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}