// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
import "./interfaces/IAddressResolver.sol";

// Based on: https://docs.synthetix.io/contracts/source/contracts/addressresolver
contract AddressResolver is Ownable, IAddressResolver {
    mapping(string => address) public repository;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(string[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            string memory name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(string[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(string calldata name) external view override returns (address) {
        return repository[name];
    }
}