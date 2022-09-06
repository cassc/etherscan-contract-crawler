// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract iPlanetReward is ERC20, Ownable {
    mapping(address => bool) minters;

    constructor() ERC20("iPlanet Reward", "IPR") {
        _mint(msg.sender, 10_000_000 ether);
    }

    function setMinter(address minter, bool state) external onlyOwner {
        minters[minter] = state;
    }

    modifier onlyMinter() {
        require(minters[msg.sender] == true, "not minter");
        _;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}