// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TixToken is ERC20, Ownable {

    constructor() ERC20("Tix Coin", "TIX") {}

    // The minimal value is 1 TIX.
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}