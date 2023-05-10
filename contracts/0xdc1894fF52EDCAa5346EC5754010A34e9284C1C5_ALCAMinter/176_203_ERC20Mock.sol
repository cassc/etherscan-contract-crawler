// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("ERC20 Mock", "ERC20MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}