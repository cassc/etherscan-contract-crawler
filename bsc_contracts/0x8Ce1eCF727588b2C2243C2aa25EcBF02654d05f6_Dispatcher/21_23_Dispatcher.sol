//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import '../interface/IStrategy.sol';
import '../interface/ITreasury.sol';
import '../interface/IPuppetOfDispatcher.sol';
import '../interface/IChainBridgeStrategy.sol';
import '../interface/IReceiver.sol';
/**
 * Distribute funds to strategic contracts
 *
 */
contract Dispatcher is Ownable, ReentrancyGuard {

    event Dispatch(address strategy, uint256 token0Amount, uint256 token1Amount);
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint256 public  percentageToWithdrawalAccount = 10000;
    uint256 public  maximumToWithdrawalAccount = ~uint256(0);
    address public  token0;
    address public token1;
    uint256 public tokenPoint0;
    uint256 public tokenPoint1;
    Receiver[] public receivers;
    mapping(address => bool) operators;

    struct Receiver {
        address to;
        uint256 point0;
        uint256 point1;
        uint8 receiverType; // 0:Strategy 1:ChainBridgeStrategy 2:WithdrawalAccount
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "WithdrawalAccount: sender is not operator");
        _;
    }

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
        operators[_msgSender()] = true;
    }

    function addReceiver(address to, uint8 receiverType, uint256 point0, uint256 point1) external onlyOwner{
        require(to != address(0), "Dispatcher: to is zero address");
        tokenPoint0 = tokenPoint0.add(point0);
        tokenPoint1 = tokenPoint1.add(point1);
        receivers.push(Receiver ({
        to: to,
        point0: point0,
        point1: point1,
        receiverType: receiverType
        }));
    }

    function updateReceiver(uint256 index, uint256 point0,uint256 point1 ) external onlyOwner {
        tokenPoint0 = tokenPoint0.sub(receivers[index].point0).add(point0);
        tokenPoint1 = tokenPoint1.sub(receivers[index].point1).add(point1);
        receivers[index].point0 = point0;
        receivers[index].point1 = point1;
    }

    function sweep(address stoken, address recipient) external onlyOwner {
        require(stoken != address(0), "Dispatcher: stoken is zero address");
        require(recipient != address(0), "Dispatcher: recipient is zero address");
        uint256 balance = IERC20(stoken).balanceOf(address(this));
        if(balance > 0) {
            IERC20(stoken).safeTransfer(recipient, balance);
        }
    }

    /**
     * Dispatch assets
     */
    function dispatch() public onlyOperator nonReentrant {
        IERC20 token0C = IERC20(token0);
        IERC20 token1C = IERC20(token1);
        uint256 token0Balance = token0C.balanceOf(address(this));
        uint256 token1Balance = token1C.balanceOf(address(this));
        require(token0Balance > 0 || token1Balance > 0, "Dispatcher: balanceOf is zero ");
        for (uint256 i = 0; i< receivers.length; i++) {
            Receiver memory s = receivers[i];
            if (s.point0 == 0 && s.point1 ==0) continue;
            uint256 token0Amount;
            uint256 token1Amount;
            if(s.point0 != 0 && token0Balance > 0)  {
                token0Amount = s.point0.mul(token0Balance).div(tokenPoint0);
                token0C.safeTransfer(s.to, token0Amount);
            }
            if (s.point1 != 0 && token1Balance > 0) {
                token1Amount = s.point1.mul(token1Balance).div(tokenPoint1);
                token1C.safeTransfer(s.to, token1Amount);
            }
            if (s.receiverType == 0) {
                IStrategy(s.to).executeStrategy();
            }
            emit Dispatch(s.to, token0Amount, token1Amount);
        }
    }

    function setOperator(address user, bool allow) external onlyOwner{
        require(user != address(0), "Dispatcher: ZERO_ADDRESS");
        operators[user] = allow;
    }

    /**
     * Transfer the funds from the deposit contract to Dispatcher
     */
    function treasuryWithdraw(address from) public onlyOperator {
        ITreasury(from).withdraw(address(this));
    }

    /**
    * Transfer the funds from the deposit contract to Dispatcher
    */
    function treasuryWithdrawAndDispatch(address from) external onlyOperator {
        ITreasury(from).withdraw(address(this));
        dispatch();
    }

    function setPuppetDispatcher(address contractAddress, address from) external onlyOwner {
        IPuppetOfDispatcher(contractAddress).setDispatcher(from);
    }

    function setPuppetOperator(address contractAddress, address user, bool allow) external onlyOwner {
        IPuppetOfDispatcher(contractAddress).setOperator(user, allow);
    }

    function setMaximumToWithdrawalAccount(uint256 _maximumToWithdrawalAccount) external onlyOwner {
        maximumToWithdrawalAccount = _maximumToWithdrawalAccount;
    }

    function setPercentageToWithdrawalAccount(uint256 _percentageToWithdrawalAccount) external onlyOwner {
        require(_percentageToWithdrawalAccount <= 10000, "Dispatcher: _percentageToWithdrawalAccount error");
        percentageToWithdrawalAccount = _percentageToWithdrawalAccount;
    }

    function receiverWithdraw(uint256 pid, uint256 leaveAmount) external onlyOperator {
        Receiver memory s = receivers[pid];
        IReceiver(s.to).withdrawToDispatcher(leaveAmount);
    }

    function receiverHarvest(uint256 pid) external onlyOperator {
        Receiver memory s = receivers[pid];
        IReceiver(s.to).harvest();
    }

    function receiverTotalAmount(uint256 pid) external view returns(uint256) {
        Receiver memory s = receivers[pid];
        return IReceiver(s.to).totalAmount();
    }

    function chainBridgeToWithdrawalAccount(uint256 pid, address token, address withdrawalAccount) external onlyOperator {
        Receiver memory s = receivers[pid];
        require(s.receiverType == 1, "Dispatcher: not chainBridge");
        uint256 amount = IChainBridgeStrategy(s.to).harvest(token);
        require(amount > 0, "Dispatcher: amount is zero");
        amount = amount.mul(percentageToWithdrawalAccount).div(10000);
        if (amount > maximumToWithdrawalAccount) {
            amount = maximumToWithdrawalAccount;
        }
        IERC20(token).safeTransfer(withdrawalAccount, amount);
    }

}