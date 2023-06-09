// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GGold is ERC20("GGold", "GGOLD"), Ownable {
    mapping(address => bool) public managers;

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    function mint(address _to, uint _amount) external {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        _mint(_to, _amount);
    }

    function burn(address _from, uint _amount) external {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        _burn(_from, _amount);
    }
}