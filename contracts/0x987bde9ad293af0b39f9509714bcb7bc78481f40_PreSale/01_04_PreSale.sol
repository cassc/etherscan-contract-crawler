// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PreSale is Ownable {
    using Address for address payable;

    uint256 public constant MAX_PER_WALLET = 10 ether;
    uint256 public constant MIN_SEND = 0.0001 ether;
    bool public active = true;

    mapping(address => uint256) public sentBy;

    event EtherSent(address indexed buyer, uint256 amount);

    receive() external payable {
        require(active, "Inactive");
        require(msg.value >= MIN_SEND, "Value < minimum");
        require(sentBy[msg.sender] + msg.value <= MAX_PER_WALLET, "Maximum per wallet reached");

        sentBy[msg.sender] += msg.value;

        emit EtherSent(msg.sender, msg.value);
    }

    function toggleActive() external onlyOwner {
        active = !active;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }
}