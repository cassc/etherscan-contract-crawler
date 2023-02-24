// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IHeritage {

    struct WillData {
        uint256 ID;
        address owner;
        address heir;
        IERC20 token; 
        uint256 creationTime;
        uint256 withdrawalTime;
        uint256 timeInterval;
        uint256 amount;
        uint256 fee;
        bool done;
    }
    
    event AddWill(
        uint256 indexed ID,
        address indexed owner,
        address indexed heir,
        IERC20 token,
        uint256 withdrawalTime, 
        uint256 amount
    );

    event UpdateWithdrawalTime(
        uint256 indexed ID,
        uint256 oldWithdrawalTime,
        uint256 newWithdrawalTime
    );

    event UpdateHeir(
        uint256 indexed ID,
        address indexed oldHeir,
        address indexed newHeir
    );

    event UpdateAmount(
        uint256 indexed ID,
        uint256 oldAmount,
        uint256 newAmount
    );

    event RemoveWill(
        uint256 indexed ID,
        address indexed owner,
        address indexed heir
    );

    event Withdraw(
        uint256 indexed ID, 
        address indexed owner, 
        address indexed heir, 
        IERC20 token,
        uint256 time,
        uint256 amount
    );

    event CollectFee(
        uint256 indexed ID, 
        IERC20 indexed token,
        uint256 amount
    );

    event SetFeeCollector(
        address indexed oldFeeCollector,
        address indexed newFeeCollector
    );

    event SetFee(
        uint256 oldFee,
        uint256 newFee
    );
}