//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import '../interface/IChainBridgeStrategy.sol';
import '../interface/IPuppetOfDispatcher.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ChainBridgeStrategy is Context, IChainBridgeStrategy,IPuppetOfDispatcher, Ownable {
    using SafeERC20 for IERC20;

    address public dispatcher;
    mapping(address => bool) public operators;
    address public receiveToken;

    event ReceiveFunds(address indexed sender, address indexed to, uint256 value);
    event SetOperator(address indexed user, bool allow );

    modifier onlyOperator() {
        require(operators[msg.sender], "ChainBridgeStrategy:sender is not operator");
        _;
    }

    modifier onlyDispatcher() {
        require(_msgSender() == dispatcher, "ChainBridgeStrategy:sender is not dispatcher");
        _;
    }

    constructor(address _receiveToken, address _dispatcher) {
        dispatcher = _dispatcher;
        receiveToken = _receiveToken;
        operators[msg.sender] = true;
        operators[dispatcher] = true;
    }

    function harvest() external override  onlyDispatcher  {
        uint256 balanceOf = IERC20(receiveToken).balanceOf(address(this));
        IERC20(receiveToken).safeTransfer(dispatcher, balanceOf);
    }

    function withdrawToDispatcher(uint256 leaveAmount) external override  onlyDispatcher  {
        require(leaveAmount > 0, "ChainBridgeStrategy: LeaveAmount is zero");
        IERC20(receiveToken).safeTransfer(dispatcher, leaveAmount);
    }

    function harvest(address token) external  override onlyDispatcher returns (uint256)  {
        uint256 balanceOf = IERC20(token).balanceOf(address(this));
        require(balanceOf > 0, "ChainBridgeStrategy: Insufficient balance");
        IERC20(token).safeTransfer(dispatcher, balanceOf);
        return balanceOf;
    }

    function totalAmount() external override view returns(uint256) {
        return IERC20(receiveToken).balanceOf(address(this));
    }

    function setOperator(address user, bool allow) external override onlyDispatcher{
        require(user != address(0), "ChainBridgeStrategy: ZERO_ADDRESS");
        operators[user] = allow;
        emit SetOperator(user, allow);
    }

    function setDispatcher(address _dispatcher) external override onlyDispatcher{
        require(_dispatcher != address(0), "ChainBridgeStrategy: ZERO_ADDRESS");
        dispatcher = _dispatcher;
    }

    function receiveFunds(address token, address to, uint256 amount) external onlyOperator {
        require(token != address(0), "ChainBridgeStrategy: token is zero address");
        require(to != address(0), "ChainBridgeStrategy: to is zero address");
        require(amount !=0, "ChainBridgeStrategy: amount is zero");
        IERC20(token).safeTransfer(to, amount);
        emit ReceiveFunds(msg.sender, to, amount);
    }
}