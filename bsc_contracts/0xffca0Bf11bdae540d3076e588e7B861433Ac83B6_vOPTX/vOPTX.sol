/**
 *Submitted for verification at BscScan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT

// vOPTX

pragma solidity 0.8.18;

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed account, address indexed spender, uint256 tokens);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event ownershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _setOwner(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Caller must be the owner.");

    _;
  }

  function renounceOwnership() external virtual onlyOwner {
    _setOwner(address(0));
  }

  function transferOwnership(address newOwner) external virtual onlyOwner {
    require(newOwner != address(0), "New owner is now the zero address.");

    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;

    emit ownershipTransferred(oldOwner, newOwner);
  }
}

contract vOPTX is Context, Ownable, IERC20 {
  string private constant _name = "Virtual OPTX";
  string private constant _symbol = "vOPTX";
  uint8 private constant _decimals = 18;

  struct tokenDataStruct {
    bool exists;
    bool active;
    address addr;
    IERC20 tokenInterface;
  }

  struct adminDataStruct {
    bool exists;
    bool active;
    address addr;
  }

  mapping(address => tokenDataStruct) tokenData;
  mapping(address => adminDataStruct) adminData;
  address[] private tokenList;
  address[] private adminList;

  event admin(address indexed addr, bool active);

  modifier onlyAdmin() {
    bool proceed = false;

    if (_msgSender() == owner()) {
      proceed = true;
    } else {
      uint256 count = adminList.length;

      for (uint256 i = 0; i < count; i++) {
        adminDataStruct memory data = adminData[adminList[i]];

        if (!data.active) { continue; }
        if (data.addr != _msgSender()) { continue; }

        proceed = true;
        break;
      }
    }

    require(proceed, "Caller must be admin.");

    _;
  }

  constructor() {
    adminData[msg.sender] = adminDataStruct(true, true, msg.sender);
    adminList.push(msg.sender);
    emit admin(msg.sender, true);

    address optxContract = 0x4Ef0F0f98326830d823F28174579C39592cDB367;

    tokenData[optxContract] = tokenDataStruct(true, true, optxContract, IERC20(optxContract));
    tokenList.push(optxContract);
  }

  function setAdmin(address addr, bool active) external onlyOwner returns (bool success) {
    if (!adminData[addr].exists) { adminList.push(addr); }

    adminData[addr] = adminDataStruct(true, active, addr);
    emit admin(addr, active);

    return true;
  }

  function getActiveAdminCount() internal view returns (uint256) {
    uint256 count = adminList.length;
    uint256 active = 1;

    unchecked {
      for (uint256 i = 0; i < count; i++) {
        adminDataStruct memory data = adminData[adminList[i]];

        if (!data.active) { continue; }
        if (data.addr == owner()) { continue; }

        active++;
      }

      return active;
    }
  }

  function getAdminList() external view returns (address[] memory) {
    uint256 count = adminList.length;
    uint256 active = getActiveAdminCount();
    uint256 a;
    address[] memory list = new address[](active);

    list[a] = owner();
    a++;

    unchecked {
      for (uint256 i = 0; i < count; i++) {
        adminDataStruct memory data = adminData[adminList[i]];

        if (!data.active) { continue; }
        if (data.addr == owner()) { continue; }

        list[a] = data.addr;
        a++;
      }

      return list;
    }
  }

  function setToken(address addr, bool active) external onlyAdmin returns (bool success) {
    if (!tokenData[addr].exists) { tokenList.push(addr); }

    tokenData[addr] = tokenDataStruct(true, active, addr, IERC20(addr));

    return true;
  }

  function getActiveTokenCount() internal view returns (uint256) {
    uint256 count = tokenList.length;
    uint256 active;

    unchecked {
      for (uint256 i = 0; i < count; i++) {
        tokenDataStruct memory data = tokenData[tokenList[i]];

        if (!data.active) { continue; }

        active++;
      }

      return active;
    }
  }

  function getTokenList() external view returns (address[] memory) {
    uint256 count = tokenList.length;
    uint256 active = getActiveTokenCount();
    uint256 a;
    address[] memory list = new address[](active);

    unchecked {
      for (uint256 i = 0; i < count; i++) {
        tokenDataStruct memory data = tokenData[tokenList[i]];

        if (!data.active) { continue; }

        list[a] = data.addr;
        a++;
      }

      return list;
    }
  }

  function name() external pure returns (string memory) { return _name; }
  function symbol() external pure returns (string memory) { return _symbol; }
  function decimals() external pure returns (uint8) { return _decimals; }
  function totalSupply() external pure returns (uint256) { return 0; }

  function transfer(address to, uint256 tokens) external pure returns (bool success) {
    if (to != address(0) && tokens > 0) { revert(); }

    return false;
  }

  function allowance(address account, address spender) external pure returns (uint256 remaining) {
    if (account != address(0) && spender != address(0)) { revert(); }

    return 0;
  }

  function approve(address spender, uint256 tokens) external pure returns (bool success) {
    if (spender != address(0) && tokens > 0) { revert(); }

    return false;
  }

  function transferFrom(address from, address to, uint256 tokens) external pure returns (bool success) {
    if (from != address(0) && to != address(0) && tokens > 0) { revert(); }

    return false;
  }

  function balanceOf(address account) external view returns (uint256 balance) {
    uint256 count = tokenList.length;

    unchecked {
      for (uint256 i = 0; i < count; i++) {
        tokenDataStruct memory data = tokenData[tokenList[i]];

        if (!data.active) { continue; }

        balance += data.tokenInterface.balanceOf(account);
      }

      return balance;
    }
  }
}