// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    function mint(address account, uint256 amount) external;
}

contract FixPriceQuacksMinter is Ownable, Pausable {

    IERC20 public quacks;

    // How many WEIs is a QUACK
    uint256 public quackWeiValue;

    address payable public etherReceiver;

    constructor(address quacksAddress) {
        quacks = IERC20(quacksAddress);
    }

    function mint() public payable whenNotPaused {
        // Solidity rounds to the lower nearest integer so if you do not
        // send exactly the difference will be kept by the etherReceiver
        quacks.mint(_msgSender(), msg.value / quackWeiValue);
        bool success = false;
        (success,) = etherReceiver.call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

    function setQuackWeiValue(uint256 newQuackWeiValue) public onlyOwner {
        quackWeiValue = newQuackWeiValue;
    }

    function setEtherReceiver(address payable newEtherReceiver) public onlyOwner {
        etherReceiver = newEtherReceiver;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}