// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProxyContracts is Ownable {

    mapping (string => address) internal contracts;

    function addContract(string memory symbol, address contractAddress) public onlyOwner {
        require(contracts[symbol] == 0x0000000000000000000000000000000000000000, "Token contract alredy exists");
        contracts[symbol] = contractAddress;
    }

    function delContract(string memory symbol) public onlyOwner {
        delete contracts[symbol];
    }

    function getContractAddress(string memory symbol) public view returns(address) {
        return contracts[symbol];
    }
}