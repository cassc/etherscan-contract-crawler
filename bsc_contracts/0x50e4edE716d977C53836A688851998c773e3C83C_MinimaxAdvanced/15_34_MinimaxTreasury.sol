// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MinimaxTreasury is OwnableUpgradeable {
    function initialize() external initializer {
        __Ownable_init();
    }

    mapping(uint => uint) public balances; // positionIndex => balance
    address public withdrawer;

    modifier onlyWithdrawer() {
        require(withdrawer == msg.sender, "onlyWithdrawer");
        _;
    }

    function setWithdrawer(address _withdrawer) public onlyOwner {
        withdrawer = _withdrawer;
    }

    function deposit(uint positionIndex) public payable {
        balances[positionIndex] += msg.value;
    }

    function withdraw(
        uint positionIndex,
        address payable destination,
        uint amount
    ) public onlyWithdrawer {
        require(balances[positionIndex] >= amount);
        destination.transfer(amount);
        balances[positionIndex] -= amount;
    }

    function withdrawAll(uint positionIndex, address payable destination) public onlyWithdrawer {
        if (balances[positionIndex] > 0) {
            destination.transfer(balances[positionIndex]);
            balances[positionIndex] = 0;
        }
    }
}