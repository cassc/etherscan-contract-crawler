/**
 *Submitted for verification at Etherscan.io on 2023-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PlayerNameRegistry {
    struct Player {
        address playerAddress;
        string[] names;
    }

    mapping(string => address) public nameToAddress;
    mapping(address => Player) public players;

    address payable public dev1;
    address payable public dev2;

    constructor(address payable _dev1, address payable _dev2) {
        dev1 = _dev1;
        dev2 = _dev2;
    }

    uint256 private constant NAME_REGISTRATION_FEE = 20000000000000000; // 0.02 Ether in Wei

    event PlayerNameRegistered(address playerAddress, string name, uint256 timestamp);

    function registerPlayerName(address playerAddress, string memory _name) public payable {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(bytes(_name).length <= 32, "Name length must be between 1 and 32 characters.");
        require(msg.value >= NAME_REGISTRATION_FEE, "Insufficient funds to register the name.");
        require(nameToAddress[_name] == address(0), "This name is already in use.");

        nameToAddress[_name] = playerAddress;
        players[playerAddress].names.push(_name);

        emit PlayerNameRegistered(playerAddress, _name, block.timestamp);

        // Distribute fees to the developers
        distributeFunds();
    }

    function getPlayerFirstName(address playerAddress) public view returns (string memory) {
        string[] storage names = players[playerAddress].names;
        require(names.length > 0, "Player has no registered names.");
        return names[0];
    }

    function getPlayerNames(address playerAddress) public view returns (string[] memory) {
        return players[playerAddress].names;
    }

    function getPlayerAddress(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }

    function distributeFunds() private {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to distribute.");

        uint256 amount = balance / 2;
        (bool success1,) = dev1.call{value: amount}("");
        require(success1, "Ether transfer to dev1 failed.");

        (bool success2,) = dev2.call{value: amount}("");
        require(success2, "Ether transfer to dev2 failed.");
    }

    fallback() external payable {
        distributeFunds();
    }

    receive() external payable {
        distributeFunds();
    }
}