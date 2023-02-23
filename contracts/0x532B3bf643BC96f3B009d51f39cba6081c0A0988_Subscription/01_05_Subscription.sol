// SPDX-License-Identifier: MIT

/*
Andro Subscription Smart Contract Disclaimer.

The Andro Subscription Smart Contract was developed by Andro Labs Development Team. The provided
contract enables a user-friendly interface to subscribe to future prizes and benefits granted
after the official release of the protocol. This Smart Contract is composed of open-source
and well-tested code deployed on the blockchain.
*/
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
* @title Subscription by Andro.
* @author Andro Labs Development Team.
*/
contract Subscription is Ownable, Pausable {

    using Counters for Counters.Counter;

    Counters.Counter public numOfSubscribers;
    uint256 public entranceFee;

    mapping (address => bool) public subscriber;

    event Subscribed(address indexed subscriber, uint256 paidFee, uint256 baseFee);
    event Withdraw(uint256 balance, address indexed to, address indexed owner);
    event EntranceFeeSet(uint256 fee, address indexed owner);
    event Unsubscribed(address subscriber);


    constructor(uint256 _entranceFee) {
        entranceFee = _entranceFee;
        emit EntranceFeeSet(_entranceFee, owner());
    }

    /**
    * @notice Subscribe
    * @dev Adds user to subscriber mapping and increase subscribers count.
    */
    function subscribe() 
        external
        payable 
        whenNotPaused
    {
        require(!subscriber[msg.sender], "SUBSCRIPTION: ALREADY_SUBSCRIBED");
        require(msg.value >= entranceFee, "SUBSCRIPTION: NOT_ENOUGH_BALANCE_FEE");

        numOfSubscribers.increment();
        subscriber[msg.sender] = true;

        emit Subscribed(msg.sender, msg.value, entranceFee);
    }

    /**
    * @notice Unsubscribed users will not be eligible.
    * @dev Decreases number of total subscribed users.
    * @dev Can only unsubscribe if subscribed previously.
    */
    function unsubscribe() 
        external 
        whenNotPaused
    {
        require(subscriber[msg.sender], "SUBSCRIPTION: NOT_SUBSCRIBED");
        assert(numOfSubscribers.current() > 0);

        numOfSubscribers.decrement();
        delete subscriber[msg.sender];

        emit Unsubscribed(msg.sender);
    }

    /** 
    * @notice Let owner withdraw funds collected by the contract.
    */
    function withdraw(address _to)
        external
        onlyOwner
    {
        require(_to != address(0), "SUBSCRIPTION: ADDRESS 0");

        uint256 contractBalance = address(this).balance;

        (bool success, ) = _to.call{value: contractBalance}("");
        require(success, "SUBSCRIPTION: WITHDRAW_FAILED");

        emit Withdraw(contractBalance, _to, owner());
    }

    /**
    * @notice Let owner set entrance fee.
    */
    function setEntranceFee(uint256 _fee)
        external
        onlyOwner
    {
        entranceFee = _fee;

        emit EntranceFeeSet(_fee, msg.sender);
    }

    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    receive() external payable {}
}