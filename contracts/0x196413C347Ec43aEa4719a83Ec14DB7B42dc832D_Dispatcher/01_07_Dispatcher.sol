// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IDispatcher.sol";
import "./utils/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/KeysMapping.sol";

contract Dispatcher is Ownable, Pausable, ReentrancyGuard, IDispatcher {
    mapping(bytes32 => address) private contracts;

    event ContractUpdated(bytes32 indexed contractKey, address indexed contractAddress);

    constructor(
        address _admin,
        string[] memory _keysMapping,
        address[] memory _contractAddresses
    ) Ownable(_admin) {
        _setContracts(_keysMapping, _contractAddresses);
    }

    function setContract(string calldata _contractKey, address _contractAddress) external override onlyOwner {
        _setContract(_contractKey, _contractAddress);
    }

    function setContracts(string[] memory _keysMapping, address[] memory _contractAddresses) external onlyOwner {
        _setContracts(_keysMapping, _contractAddresses);
    }

    function getContract(bytes32 _contractKey) external view override returns (address) {
        return contracts[_contractKey];
    }

    function _setContract(string memory _contractKey, address _contractAddress) internal {
        bytes32 key = KeysMapping.keyToId(_contractKey);
        contracts[key] = _contractAddress;

        emit ContractUpdated(key, _contractAddress);
    }

    function _setContracts(string[] memory _keysMapping, address[] memory _contractAddresses) internal {
        require(_keysMapping.length == _contractAddresses.length, "setContracts function information arity mismatch");

        for (uint256 i = 0; i < _keysMapping.length; i++) {
            _setContract(_keysMapping[i], _contractAddresses[i]);
        }
    }
}