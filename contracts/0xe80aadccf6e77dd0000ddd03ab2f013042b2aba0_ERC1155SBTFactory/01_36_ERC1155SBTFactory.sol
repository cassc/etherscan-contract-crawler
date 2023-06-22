// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155SBT.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";

contract ERC1155SBTFactory is Ownable {
    address[] public contracts;
    address[] public externalContracts;
    mapping(address => bool) public isFactoryCreatedContract;
    mapping(address => bool) public isExternalContract;

    constructor() {
        _setupOwner(msg.sender);
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _owner,
        address _operator
    ) public {
        ERC1155SBT newContract = new ERC1155SBT(_name, _symbol, _royaltyRecipient, _royaltyBps, _owner, _operator);
        contracts.push(address(newContract));
        isFactoryCreatedContract[address(newContract)] = true;
    }

    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    //////////// Factory Contracts ////////////
    function getAddress(uint _index) external view returns (address) {
        return contracts[_index];
    }

    function getAddresses() public view returns (address[] memory) {
        return contracts;
    }

    function getLength() external view returns (uint) {
        return contracts.length;
    }
    //////////// Factory Contracts ////////////

    //////////// External Contracts ////////////
    function addContract(address _address) onlyOwner external {
        externalContracts.push(_address);
        isExternalContract[_address] = true;
    }

    function getExternalAddress(uint _index) external view returns (address) {
        return externalContracts[_index];
    }

    function getExternalAddresses() public view returns (address[] memory) {
        return externalContracts;
    }

    function getExternalLength() external view returns (uint) {
        return externalContracts.length;
    }
    //////////// External Contracts ////////////
}