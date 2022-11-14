// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GreatResilientIncentive is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("GreatResilientIncentive", "GRI") {
        _mint(msg.sender, 6000000000 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}