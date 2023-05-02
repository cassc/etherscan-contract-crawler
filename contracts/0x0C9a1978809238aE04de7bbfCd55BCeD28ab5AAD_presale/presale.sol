/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

abstract contract Context {
function _msgSender() internal view virtual returns (address) {
return msg.sender;
}

function _msgData() internal view virtual returns (bytes calldata) {
return msg.data;
}
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
address private _owner;

event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

/**
* @dev Initializes the contract setting the deployer as the initial owner.
*/
constructor() {
_transferOwnership(_msgSender());
}

/**
* @dev Throws if called by any account other than the owner.
*/
modifier onlyOwner() {
_checkOwner();
_;
}

/**
* @dev Returns the address of the current owner.
*/
function owner() public view virtual returns (address) {
return _owner;
}

/**
* @dev Throws if the sender is not the owner.
*/
function _checkOwner() internal view virtual {
require(owner() == _msgSender(), "Ownable: caller is not the owner");
}

/**
* @dev Leaves the contract without owner. It will not be possible to call
* `onlyOwner` functions. Can only be called by the current owner.
*
* NOTE: Renouncing ownership will leave the contract without an owner,
* thereby disabling any functionality that is only available to the owner.
*/
function renounceOwnership() public virtual onlyOwner {
_transferOwnership(address(0));
}

/**
* @dev Transfers ownership of the contract to a new account (`newOwner`).
* Can only be called by the current owner.
*/
function transferOwnership(address newOwner) public virtual onlyOwner {
require(newOwner != address(0), "Ownable: new owner is the zero address");
_transferOwnership(newOwner);
}

/**
* @dev Transfers ownership of the contract to a new account (`newOwner`).
* Internal function without access restriction.
*/
function _transferOwnership(address newOwner) internal virtual {
address oldOwner = _owner;
_owner = newOwner;
emit OwnershipTransferred(oldOwner, newOwner);
}
}

pragma solidity ^0.8.18;

interface IERC20 {

function totalSupply() external view returns (uint256);

function balanceOf(address account) external view returns (uint256);

function transfer(address recipient, uint256 amount) external returns (bool);

function allowance(address owner, address spender) external view returns (uint256);

function approve(address spender, uint256 amount) external returns (bool);

function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

event Transfer(address indexed from, address indexed to, uint256 value);

event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract presale is Ownable{

IERC20 public p2ptoken;

uint256 public rate = 1000000000 ;
uint256 public minAmt = 0.05 ether ;
uint256 public maxAmt = 0.5 ether ;
constructor(address _tokenAddress) {
require(address(_tokenAddress) != address(0),"Token Address cannot be address 0");
p2ptoken = IERC20(_tokenAddress);

}

function changeSetting( uint256 _rate , uint256 _minAmt , uint256 _maxAmt ) public onlyOwner {
rate = _rate;
minAmt = _minAmt;
maxAmt = _maxAmt ;
}

function buyToken() external payable {
require(minAmt <= msg.value);
require(maxAmt >= msg.value);
payable(owner()).transfer(address(this).balance);
uint256 amount = viewCalculate(msg.value) ;
p2ptoken.transfer(msg.sender, amount);

}

function viewCalculate(uint256 _eth ) public view returns(uint256){
uint256 amount = _eth * rate * 10e8/10e18 ;
return amount ;
}
function emergencyWithdrawNative() public onlyOwner {
payable(msg.sender).transfer(address(this).balance);
}
function emergencyWithdrawErc20(address tokenAddress) public onlyOwner {
IERC20 token = IERC20(tokenAddress);
token.transfer(msg.sender, token.balanceOf(address(this)));
}

}