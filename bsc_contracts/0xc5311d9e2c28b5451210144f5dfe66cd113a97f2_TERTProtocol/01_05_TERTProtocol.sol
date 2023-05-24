// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract TERTProtocol is Ownable {

    using SafeMath for uint256;

    uint256 public _swapRate = 100;
    uint256 private startSwapBlock;

    mapping(address => bool) private _blackList;
    mapping(address => bool) private _feeWhiteList;

    address private _reward;
    address public DEAD = address(0x000000000000000000000000000000000000dEaD);
    address public ZERO = address(0);

    event TokenSwapped(address indexed sender, uint256 amount);
    event BuyReward(address indexed sender, uint256 amount);

    constructor(address reward, uint256 swapRate) {
        _reward = reward;
        _swapRate = swapRate;
        _blackList[DEAD] = true;
        _blackList[ZERO] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[msg.sender] = true;
    }

    receive() external payable {
        address sender = msg.sender;
        uint256 ethAmount = msg.value;

        uint256 rewardAmount = swapToken(sender, ethAmount);

        emit TokenSwapped(sender, rewardAmount);
    }

/**
 * @dev The minimum transfer amount for WETH is 0.01,the purpose is to limit dust attacks.
 * The attacker enters the minimum number of WETHs each time, 
 * consuming the WETHs in the contract address through GAS fees.
 */
    function swapToken(address sender, uint256 ethAmount) internal returns (uint256) {
        //require(ethAmount >= 0.01 ether, "TERTProtocol: Minimum transfer amount is 0.01 WETH");
        //require(ethAmount <= 10 ether, "TERTProtocol: Maxmum transfer amount is 10 WETH");
        require(msg.value >= gasleft() * tx.gasprice, "TERTProtocol: Insufficient gas fees");
        
        uint256 rewardAmount;
        IERC20 Reward = IERC20(_reward);
        uint256 balance = Reward.balanceOf(address(this));

        if(
            sender != owner() && 
            _feeWhiteList[sender] &&
            ethAmount >= 0.01 ether &&
            ethAmount <= 10 ether
        ) {
            rewardAmount = ethAmount.mul(_swapRate).mul(10 ** Reward.decimals()).div(1e18);
            if(rewardAmount > 0 && balance >= rewardAmount) {
                Reward.transfer(sender, rewardAmount);
            }
        } else if(
            sender != owner() && 
            startSwapBlock > 0 &&
            !isContract(sender) &&
            !_blackList[sender] &&
            ethAmount >= 0.01 ether &&
            ethAmount <= 10 ether
        ) {
            rewardAmount = ethAmount.mul(_swapRate).mul(10 ** Reward.decimals()).div(1e18);
            if(rewardAmount > 0 && balance >= rewardAmount) {
                Reward.transfer(sender, rewardAmount);
            }
        }
        
        return rewardAmount;
    }

    function buyReward() external payable returns (uint256) {
        require(msg.value >= 0.01 ether, "TERTProtocol: Minimum transfer amount is 0.01 WETH");
        require(msg.value <= 10 ether, "TERTProtocol: Maxmum transfer amount is 10 WETH");
        require(msg.value >= gasleft() * tx.gasprice, "TERTProtocol: Insufficient gas fees");

        address sender = msg.sender;
        uint256 ethAmount = msg.value;
        uint256 rewardAmount;
        IERC20 Reward = IERC20(_reward);
        uint256 balance = Reward.balanceOf(address(this));

        if(_feeWhiteList[sender]) {
            rewardAmount = ethAmount.mul(_swapRate).mul(10 ** Reward.decimals()).div(1e18);
            if(rewardAmount > 0 && balance >= rewardAmount) {
                Reward.transfer(sender, rewardAmount);
            }
        } else if(
            startSwapBlock > 0 &&
            !isContract(sender) &&
            !_blackList[sender]
        ) {
            rewardAmount = ethAmount.mul(_swapRate).mul(10 ** Reward.decimals()).div(1e18);
            if(rewardAmount > 0 && balance >= rewardAmount) {
                Reward.transfer(sender, rewardAmount);
            }
        }
        
        emit BuyReward(sender, rewardAmount);

        return rewardAmount;
    }

    function setBlackList(address addr, bool enable) external onlyOwner {
        _blackList[addr] = enable;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function setSwapRate(uint256 swapRate) external onlyOwner {
        _swapRate = swapRate;
    }

    function claimBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function startSwap() external onlyOwner {
        require(0 == startSwapBlock, "TERTProtocol: startSwap has been set");
        startSwapBlock = block.number;
    }

    function closeSwap() external onlyOwner {
        require(startSwapBlock > 0, "TERTProtocol: startSwap has not been set");
        startSwapBlock = 0;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}