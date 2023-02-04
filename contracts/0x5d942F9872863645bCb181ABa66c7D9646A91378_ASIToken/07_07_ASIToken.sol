// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ASIToken is ERC20Capped, Ownable {
    constructor(uint256 _initialSupply, uint256 _cap)
    ERC20("AltSignals", "ASI")
    ERC20Capped(_cap * 10**decimals())
    Ownable() {
        _mint(msg.sender, _initialSupply * 10**decimals());
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    /// @notice Contract is still ERC20Capped
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}