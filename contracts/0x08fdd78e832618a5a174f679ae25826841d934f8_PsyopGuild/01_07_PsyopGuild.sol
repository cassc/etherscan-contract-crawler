// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PsyopGuild is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 500_000_000_000_000;

    constructor() ERC20("Psyop Guild", "PSYG") {
        _mint(
            0x269b665FBF48b3b9e8083a92177ee53C9351932F,
            500_000_000_000_000 * 10**decimals()
        );
        renounceOwnership();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Reached to Max Supply");
        _mint(to, amount);
    }
}