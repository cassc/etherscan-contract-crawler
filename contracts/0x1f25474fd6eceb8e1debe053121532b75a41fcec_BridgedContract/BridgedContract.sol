/**
 *Submitted for verification at Etherscan.io on 2023-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BridgedContract {
    address public owner;

    event Locked(address indexed asset, address indexed from, address indexed to, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Send Ether by the owner
    function sendFunds(address payable _to, uint256 _value) public onlyOwner {
        require(address(this).balance >= _value, "Insufficient Ether balance");
        _to.transfer(_value);
        emit Locked(address(0), msg.sender, _to, _value);
    }
    
    // Send Ether by anyone
    function sendFundsByAnyone(address payable _to, uint256 _value) public {
        require(msg.sender.balance >= _value, "Insufficient Ether balance");
        _to.transfer(_value);
        emit Locked(address(0), msg.sender, _to, _value);
    }

    // Send ERC-20 Tokens by the owner
    function sendTokens(address _tokenAddress, address _to, uint256 _value) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, _to, _value), "Token transfer failed");
        emit Locked(_tokenAddress, msg.sender, _to, _value);
    }

    // Send ERC-20 Tokens by anyone
    function sendTokensByAnyone(address _tokenAddress, address _to, uint256 _value) public {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, _to, _value), "Token transfer failed");
        emit Locked(_tokenAddress, msg.sender, _to, _value);
    }

    // Withdraw ERC-20 Tokens by the owner to a specific address
    function withdrawTokens(address _tokenAddress, address _to, uint256 _value) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= _value, "Insufficient token balance");
        require(token.transfer(_to, _value), "Token withdrawal failed");
        emit Locked(_tokenAddress, address(this), _to, _value);
    }

    // Withdraw Ether by the owner to a specific address
    function withdrawFunds(address payable _to, uint256 _value) public onlyOwner {
        require(address(this).balance >= _value, "Insufficient Ether balance");
        _to.transfer(_value);
        emit Locked(address(0), address(this), _to, _value);
    }

    receive() external payable {
        // Enable the contract to receive Ether
    }

    fallback() external payable {
        // Enable the contract to receive Ether
    }
}