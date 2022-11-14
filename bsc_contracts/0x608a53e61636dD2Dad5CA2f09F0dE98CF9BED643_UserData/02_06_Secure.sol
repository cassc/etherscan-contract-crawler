// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Secure is Ownable {
  event AddBlacklist(address indexed user);
  event RemoveBlacklist(address indexed user);
  event AuthorizeContract(address indexed smartContract);
  event DeauthorizeContract(address indexed smartContract);

  mapping(address => bool) public blacklist;
  mapping(address => bool) public contracts;

  bytes4 private constant TRANSFER =
    bytes4(keccak256(bytes("transfer(address,uint256)")));

  modifier onlyContract() {
    require(contracts[_msgSender()], "USER::ONC");
    _;
  }

  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{gas: 23000, value: value}("");

    require(success, "USER::ETH");
  }

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(TRANSFER, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), "USER::TTF");
  }

  function addListBlacklist(address[] memory users) external onlyContract {
    for (uint8 i = 0; i < users.length; i++) {
      blacklist[users[i]] = true;
    }
  }

  function removeListBlacklist(address[] memory users) external onlyContract {
    for (uint8 i = 0; i < users.length; i++) {
      blacklist[users[i]] = false;
    }
  }

  function addBlacklist(address user) external onlyContract {
    blacklist[user] = true;
    emit AddBlacklist(user);
  }

  function removeBlacklist(address user) external onlyContract {
    blacklist[user] = false;
    emit RemoveBlacklist(user);
  }

  function authorizeContract(address smartContract) public onlyOwner {
    contracts[smartContract] = true;
    emit AuthorizeContract(smartContract);
  }

  function deauthorizeContract(address smartContract) public onlyOwner {
    contracts[smartContract] = false;
    emit DeauthorizeContract(smartContract);
  }

  function withdrawToken(address token, uint256 value) external onlyOwner {
    _safeTransfer(token, owner(), value);
  }

  function withdrawBnb(uint256 value) external onlyOwner {
    payable(owner()).transfer(value);
  }
}