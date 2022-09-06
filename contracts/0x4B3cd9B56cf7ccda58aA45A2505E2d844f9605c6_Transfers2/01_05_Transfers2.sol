// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Transfers2 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Transaction {
        string tid;
        uint256 amount;
        string operation;
        address userAddress;
        string currency;
    }
    address public USDC;
    address public owner;
    bool pause;
    mapping(string => Transaction) private depositTransactions;
    mapping(string => Transaction) private withdrawTransactions;

    event TransactionCreated(
        string tid,
        uint256 amount,
        bool submited,
        string message,
        string currency
    );

    constructor() {
        USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; 
        owner = 0xC03d0aF74cf3d08D92A236F0691CbAb0b8C8830d;
        pause = false;
    }

    modifier isPause() {
        require(pause == false, "the contract has been paused");
        _;
    }

    modifier findDeposit_TX(string calldata _tid) {
        require(
            depositTransactions[_tid].amount != 0,
            "Deposit transactions not found"
        );
        _;
    }

    modifier isValidDeposit_TX(string calldata _tid) {
        require(
            depositTransactions[_tid].amount == 0,
            "Deposit transaction already exists"
        );
        _;
    }

    modifier isValidWithdraw_TX(string calldata _tid) {
        require(
            withdrawTransactions[_tid].amount == 0,
            "Withdrawal transaction already exists"
        );
        _;
    }

    modifier enoughDeposit(uint256 _amount) {
        uint256 balance = IERC20(USDC).balanceOf(msg.sender);
        uint256 amount = _amount * 10**18;
        require(
            balance >= amount && amount != 0,
            "You dont have enough balance"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner of this contract");
        _;
    }

    function deposit(string calldata _tid, uint256 _amount)
        external
        isPause
        enoughDeposit(_amount)
        isValidDeposit_TX(_tid)
        nonReentrant
    {
        SafeERC20.safeTransferFrom(
            IERC20(USDC),
            msg.sender,
            address(this),
            _amount * 10**18
        );
        Transaction memory newTransaction = Transaction(
            _tid,
            _amount,
            "inc",
            msg.sender,
            "USDC"
        );
        depositTransactions[_tid] = newTransaction;
        emit TransactionCreated(_tid, _amount, true, "Confirmed" , "USDC");
    }

    function getDepositTransaction(string calldata _tid)
        external
        view
        findDeposit_TX(_tid)
        returns (Transaction memory)
    {
        return depositTransactions[_tid];
    }
    
    function withdraw(string calldata _tid, uint256 _amount , address _receiver)
        public
        isPause
        isValidWithdraw_TX(_tid)
        nonReentrant
        onlyOwner
    {
        Transaction memory newTransaction = Transaction(
            _tid,
            _amount,
            "dec",
            _receiver,
            "USDC"
        );
        withdrawTransactions[_tid] = newTransaction;
        SafeERC20.safeTransfer(
            IERC20(USDC),
            _receiver,
            _amount 
        );
        emit TransactionCreated(_tid, _amount, true, "Confirmed", "USDC");
    }

    function contractUSDCs() external view returns (uint256) {
        uint256 balance = IERC20(USDC).balanceOf(address(this));
        return balance;
    }

    function enablePause() external onlyOwner {
        pause = true;
    }

    function disablePause() external onlyOwner {
        pause = false;
    }

    function withdrawUSDC(address receiver , uint256 _amount) public onlyOwner {
        SafeERC20.safeTransfer(
            IERC20(USDC),
            receiver,
            _amount 
        );
    }
}