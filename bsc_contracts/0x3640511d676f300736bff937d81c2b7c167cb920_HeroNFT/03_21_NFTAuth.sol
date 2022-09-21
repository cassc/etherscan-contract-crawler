// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./Auth.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract NFTAuth is Auth, ContextUpgradeable {
  mapping(address => bool) public mintAdmins;
  mapping(address => bool) public transferable;
  mapping(address => bool) public gameContracts;
  address public upgradingContract;

  function initialize(address _mainAdmin) virtual override public {
    Auth.initialize(_mainAdmin);
  }

  modifier onlyMintAdmin() {
    require(_isMintAdmin() || _isMainAdmin(), "NFTAuth: Only mint admin");
    _;
  }

  modifier onlyTransferAdmin() {
    require(_isTransferAble() || _isMainAdmin(), "NFTAuth: Only transfer admin");
    _;
  }

  modifier onlyGameContract() {
    require(_isGameContracts() || _isMainAdmin(), "NFTAuth: Only game contract");
    _;
  }

  modifier onlyUpgradingContract() {
    require(_isUpgradingContract() || _isMainAdmin(), "NFTAuth: Only upgrading Contract");
    _;
  }

  function _isMintAdmin() internal view returns (bool) {
    return mintAdmins[_msgSender()];
  }

  function _isTransferAble() internal view returns (bool) {
    return transferable[_msgSender()];
  }

  function _isGameContracts() internal view returns (bool) {
    return gameContracts[_msgSender()];
  }

  function _isUpgradingContract() internal view returns (bool) {
    return _msgSender() == upgradingContract;
  }

  function updateMintAdmin(address _address, bool _mintAble) onlyMainAdmin external {
    require(_address != address(0), "NFTAuth: Address invalid");
    mintAdmins[_address] = _mintAble;
  }

  function updateTransferable(address _address, bool _transferable) onlyMainAdmin external {
    require(_address != address(0), "NFTAuth: Address invalid");
    transferable[_address] = _transferable;
  }

  function updateGameContract(address _contract, bool _status) onlyMainAdmin external {
    require(_contract != address(0), "NFTAuth: Address invalid");
    gameContracts[_contract] = _status;
  }

  function updateUpgradingContract(address _contract) onlyMainAdmin external {
    require(_contract != address(0), "NFTAuth: Address invalid");
    upgradingContract = _contract;
  }
}