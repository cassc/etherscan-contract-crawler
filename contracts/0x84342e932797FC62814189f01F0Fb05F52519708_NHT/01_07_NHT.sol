pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NHT is ERC20Capped, Ownable {
    constructor(uint256 initial_, uint256 cap_) Ownable() ERC20("Neighbourhoods Token", "NHT") ERC20Capped(cap_) {
        ERC20._mint(msg.sender, initial_);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }
}