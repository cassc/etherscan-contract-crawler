// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Smart is ERC20, ERC20Burnable, Ownable {

    constructor() ERC20("Smart", "SMA") {
        uint256 initialSupply = 100000000 * 10**decimals();

        _mint(_msgSender(), initialSupply);
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }
}