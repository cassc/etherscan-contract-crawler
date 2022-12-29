// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract TokenDumperUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  bool public isEnabled;
  address public vault;

  function initialize(address vault_) external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    setVault(vault_);
  }


  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}


  // nonpayable
  function purchase(address token, uint256 amount) external {
    require(isEnabled, "Purchases disabled");
    IERC20(token).transferFrom(msg.sender, vault, amount);
    _sendValue(payable(msg.sender), 1, gasleft());
  }

  // nonpayable - admin
  function setEnabled(bool newEnabled) external onlyOwner{
    isEnabled = newEnabled;
  }

  function setVault(address vault_) public onlyOwner{
    vault = vault_;
  }

  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "no funds available");
    _sendValue(payable(owner()), totalBalance, gasleft());
  }

  // internal
  function _sendValue(address payable recipient, uint256 amount, uint256 gasLimit) internal {
    require(address(this).balance >= amount, "Insufficient balance");

    (bool success, ) = recipient.call{gas: gasLimit, value: amount}("");
    require(success, "Call with value failed");
  }

  //internal - admin
  function _authorizeUpgrade(address) internal override onlyOwner {
    // owner check
  }
}