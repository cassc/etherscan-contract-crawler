/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
  function decimals() external pure returns (uint8);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, account);
        _owner = account;
    }

}

contract rewardPoolv1 is Context, Ownable {

  mapping(address => bool) public permission;

  modifier onlyPermission() {
    require(permission[msg.sender], "!PERMISSION");
    _;
  }

  constructor() {}

  function flagePermission(address _account,bool _flag) public onlyOwner returns (bool) {
    permission[_account] = _flag;
    return true;
  }

  function executeToken(address tokenaddress,address receiver,uint256 amount) external onlyPermission returns (bool) {
    IERC20 token = IERC20(tokenaddress);
    token.transfer(receiver,amount);
    return true;
  }

  function emergencyWithdraw(address tokenaddress) external onlyOwner {
    IERC20 token = IERC20(tokenaddress);
    uint256 amount = token.balanceOf(address(this));
    token.transfer(msg.sender,amount);
  }

  function callStuckETH() external onlyOwner {
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "Failed to send ETH");
  }
  
  receive() external payable { }
}