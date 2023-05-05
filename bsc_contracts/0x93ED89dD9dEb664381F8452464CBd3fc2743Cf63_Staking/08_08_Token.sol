// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ULFX is ERC20, ERC20Burnable, Ownable {
    constructor(
        uint256 _initialSupply,
        address _stakingContract
    ) ERC20("ULFPAD", "ULFX") Ownable() {
        _mint(msg.sender, _initialSupply);
        transferOwnership(_stakingContract);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}