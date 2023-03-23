// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./xGorilla.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract xGorillaStakeable is xGorilla, Ownable {

    constructor(string memory _name, string memory _symbol)
        xGorilla(_name, _symbol)
    {
        _mint(msg.sender, 1000000000* 10**decimals());
    }


    // Set rewards per hour as x/10.000.000 (Example: 100.000 = 1%)
    function setRewards(uint256 _rewardsPerHour) public onlyOwner {
        rewardsPerHour = _rewardsPerHour;
    }

    // Set the minimum amount for staking in wei
    function setMinStake(uint256 _minStake) public onlyOwner {
        minStake = _minStake;
    }

    // Set the minimum time that has to pass for a user to be able to restake rewards
    function setCompFreq(uint256 _compoundFreq) public onlyOwner {
        compoundFreq = _compoundFreq;
    }

    // Set the minimum time that has to pass for a user to be able to restake rewards
    function setGorillaAddress(address  _Gorilla) public onlyOwner {
        Gorilla = _Gorilla;
    }
}