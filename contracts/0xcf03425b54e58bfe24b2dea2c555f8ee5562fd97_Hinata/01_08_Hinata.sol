//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Hinata is ERC20Capped, ERC20Burnable, Ownable {
    // contract that taking care of reward for staking
    address public chef;

    constructor() ERC20("Hinata", "HNTAI") ERC20Capped(100000000 * 10 ** 18) {}

    function _mint(address account, uint256 amount) internal override(ERC20Capped, ERC20) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function mint(address to, uint256 amount) external {
        assert(msg.sender != address(0));
        require(msg.sender == owner() || msg.sender == chef, "Hinata: not owner or chef");
        _mint(to, amount);
    }

    function setChef(address chef_) external onlyOwner {
        chef = chef_;
    }
}