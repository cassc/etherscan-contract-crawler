// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract sHuH is ERC20, ERC20Burnable {
    address public stake;
    uint8 private _decimals;
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,        
        address _stake
        ) ERC20(name, symbol) {
        stake=_stake;
        _decimals=decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) public {
        require(_msgSender()==stake, "Not a stake!");
        _mint(to, amount);
    }
}