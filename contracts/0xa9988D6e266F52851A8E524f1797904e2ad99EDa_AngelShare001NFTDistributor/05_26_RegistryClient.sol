// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRegistry {
    function getAddr(string memory id) external view returns (address);

    function updateAddr(string memory id, address addr) external;
}

/**
 * @dev used to look up other Ethlas contract addresses by name from Ethlas contract registry
 */
contract RegistryClient is Ownable {
    address public registryAddr;

    function setAddr(address addr) internal {
        registryAddr = addr;
    }

    function updateAddr(address addr) external onlyOwner {
        registryAddr = addr;
    }

    function lookupContractAddr(string memory contractName) internal view returns (address) {
        require(registryAddr != address(0), "registry address not initialized");
        IRegistry reg = IRegistry(registryAddr);
        return reg.getAddr(contractName);
    }
}