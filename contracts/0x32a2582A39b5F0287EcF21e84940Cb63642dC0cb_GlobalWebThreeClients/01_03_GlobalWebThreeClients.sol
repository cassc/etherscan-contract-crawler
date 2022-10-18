// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

error Clients__WithdrawalFailed();
error Clients__ClientAlreadyAdded();

contract GlobalWebThreeClients is Ownable {
    address private immutable i_partnerAccount;
    address[] private s_clients;
    mapping(address => uint256) private s_clientIndex;

    event clientAdd(address indexed client);
    event clientRemove(uint256 indexed index);

    constructor() {
        i_partnerAccount = 0x3C67F48c548738Bda7EDD74213e8AD1820c3DD2a;
        s_clients.push(0x0000000000000000000000000000000000000000);
    }

    function addClient(address client) public onlyOwner {
        if (s_clientIndex[client] != 0) {
            revert Clients__ClientAlreadyAdded();
        }

        s_clients.push(client);
        s_clientIndex[client] = (s_clients.length) - 1;

        emit clientAdd(client);
    }

    function removeClient(uint256 index) public onlyOwner {
        delete s_clientIndex[s_clients[index]];
        delete s_clients[index];

        emit clientRemove(index);
    }

    receive() external payable {}

    function withdrawFunds() public onlyOwner {
        (bool success, ) = i_partnerAccount.call{value: address(this).balance}("");
        if (!success) {
            revert Clients__WithdrawalFailed();
        }
    }

    function getClientsIndex(address clientAddress) public view returns (uint256) {
        return s_clientIndex[clientAddress];
    }

    function getClients(uint256 index) public view returns (address) {
        return s_clients[index];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}