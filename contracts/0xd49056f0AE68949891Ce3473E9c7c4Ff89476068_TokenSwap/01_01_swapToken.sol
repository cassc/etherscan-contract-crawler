// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TokenSwap {
    address public OProtocol;
    address public ZkInu;
    address public owner;
    
    constructor(address _OProtocol, address _ZkInu) {
        OProtocol = _OProtocol;
        ZkInu = _ZkInu;
        owner = msg.sender;
    }
    

      function swapTokens(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        
        uint256 contractBalance = IERC20(OProtocol).balanceOf(address(this));
        uint256 UserBalance = IERC20(ZkInu).balanceOf(msg.sender);    
        require(contractBalance >= amount, "Insufficient 0xProtocol Tokens");
        require(UserBalance >= amount, "Insufficient ZkInu Tokens");
        IERC20(ZkInu).approve(msg.sender,amount);
        IERC20(ZkInu).transferFrom(msg.sender, address(this), amount);
        IERC20(OProtocol).transfer( msg.sender, amount);
  
    }

  
    
    function withdrawTokens(address tokenAddress) external {
        require(msg.sender == owner, "Only owner can withdraw tokens");
        require(tokenAddress != OProtocol && tokenAddress != ZkInu, "Cannot withdraw swap tokens");
        
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        IERC20(tokenAddress).transfer(owner, balance);
    }
}