//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import '../interface/IPuppetOfDispatcher.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

//
contract Treasury is ReentrancyGuard,Context,IPuppetOfDispatcher, Ownable {

    using SafeERC20 for IERC20;

    event Deposit(address user, uint256 amount, address recAddress);
    event Withdraw(address recipient, uint256 amount);
    event Sweep(address token, address recipient, uint256 amount);
    event SetOperator(address indexed user, bool allow );

    address public token;
    address public dispatcher;
    mapping(address => bool) public operators;

    constructor(address _token, address _dispatcher) {
        token = _token;
        dispatcher = _dispatcher;
        operators[msg.sender] = true;
        operators[dispatcher] = true;
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "Treasury: sender is not operator");
        _;
    }

    modifier onlyDispatcher() {
        require(dispatcher == _msgSender(), "Treasury: caller is not the dispatcher");
        _;
    }

    function deposit(uint256 amount, address recaddress) external nonReentrant{
        require(amount != 0, "Treasury: amount is zero");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, recaddress);
    }

    function withdraw(address recipient) external onlyDispatcher{
        require(recipient != address(0), "Treasury: recipient is zero address");
        uint256 balanceOf = IERC20(token).balanceOf(address(this));
        if(balanceOf > 0) {
            IERC20(token).safeTransfer(recipient, balanceOf);
        }
        emit Withdraw(recipient, balanceOf);
    }

    function sweep(address stoken, address recipient) external onlyOperator{
        uint256 balance = IERC20(stoken).balanceOf(address(this));
        if(balance > 0) {
            IERC20(stoken).safeTransfer(recipient, balance);
            emit Sweep(stoken, recipient, balance);
        }
    }

    function setDispatcher(address _dispatcher) external override onlyDispatcher {
        require(_dispatcher != address(0), "Treasury: dispatcher is zero address");
        dispatcher = _dispatcher;
    }

    function setOperator(address user, bool allow) external override onlyDispatcher{
        require(user != address(0), "WithdrawalAccount: ZERO_ADDRESS");
        operators[user] = allow;
        emit SetOperator(user, allow);
    }
}