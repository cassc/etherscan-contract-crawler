// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BNBOneScatter is Initializable {
    address[] public receivers;
    address public owner;

    function initialize() external initializer {
        owner = msg.sender;
    }

    function addReceiver(address addr) external onlyOwner {
        receivers.push(addr);
    }

    function removeReceiver(uint index) external onlyOwner {
        require(index < receivers.length);
        receivers[index] = receivers[receivers.length - 1];
        receivers.pop();
    }

    function getReceiverIndex(address addr) external view returns (uint256) {
        uint256 length = receivers.length;
        for (uint256 i = 0; i < length; ++i) {
            if (addr == receivers[i]) return i;
        }
        revert("Address is not found");
    }

    function scatterSend() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance.");

        uint256 length = receivers.length;
        require(length > 0, "No receivers.");

        uint256 value = balance / length;
        for (uint256 i = 0; i < length; ++i) {
            payable(receivers[i]).transfer(value);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}