// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AuthorizedAgent is Ownable {
    mapping(address => bool) private agentAddresses;

    event AddAgent(address _address);
    event RemoveAgent(address _address);

    function addAgent(address _address) external onlyOwner {
        agentAddresses[_address] = true;
        emit AddAgent(_address);
    }

    function isAgent(address _address) public view returns (bool) {
        return agentAddresses[_address];
    }

    function removeAgent(address _address) external onlyOwner {
        delete agentAddresses[_address];
        emit RemoveAgent(_address);
    }
}