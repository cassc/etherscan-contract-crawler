// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFOtoken is ERC20, ERC20Burnable, Ownable {

    address public stake;

    constructor() ERC20("NFOtoken", "NFO") {}

    function claimReward(address _address, uint _amount)
        public 
    {
        require(msg.sender == stake, "only claimable through stake");
        _mint(_address, _amount);
    }

    // Setters

    function setStake(address _address) public onlyOwner {
        stake = _address;
    }
}