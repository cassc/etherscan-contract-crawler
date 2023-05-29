// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './dependencies/uniswap-v2-periphery/contracts/dependencies/uniswap-v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import './dependencies/uniswap-v2-periphery/contracts/dependencies/uniswap-v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import './dependencies/uniswap-v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './interfaces/IRebalancer.sol';
import './interfaces/ILPStaking.sol';

contract Rena is ERC20("Rena", "RENA"), Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    //Needed Addresses
    address public WETH;
    address public renaRouter;
    address public uniRouter;
    address public uniFactory;
    address public uniPair;
    address public renaFactory;

    address payable public treasury;

    //Objects
    address payable public rebalancer;
    address public feeDistributor;
    address public claim;
    address public lpStaking;

    //Fee Divisors
    uint16 public feeDivisor;
    uint16 public callerRewardDivisor;
    uint16 public rebalancerDivisor;

    //Map toggles
    mapping(address => bool) feeless;

    //Overflow protected
    uint256 public minimumRebalanceAmount;
    uint256 public lastRebalance;
    uint256 public rebalanceInterval;

    constructor (
        address renaRouter_,
        address uniRouter_,
        uint256 minimumReblanceAmount_,
        uint256 rebalanceInterval_
        ) {
        treasury = msg.sender;

        feeDivisor = 100;
        callerRewardDivisor = 40;
        rebalancerDivisor = 200;

        minimumRebalanceAmount = minimumReblanceAmount_;

        renaRouter = renaRouter_;
        uniRouter = uniRouter_;
        WETH = IUniswapV2Router02(uniRouter).WETH();
        uniFactory = IUniswapV2Router02(uniRouter).factory();
        uniPair = IUniswapV2Factory(uniFactory).createPair(address(this), WETH);
        
        feeless[address(this)] = true;
        feeless[msg.sender] = true;

        lastRebalance = block.timestamp;
        rebalanceInterval = rebalanceInterval_;

        _mint(msg.sender, 11000000 * 1e18);
    }


    function _transfer(address from, address to, uint256 amount) internal override {
        if(feeDivisor > 0 && feeless[from] == false && feeless[to] == false) {
            uint256 feeAmount = amount.div(feeDivisor);
            super._transfer(from, address(feeDistributor), feeAmount);
            super._transfer(from, to, amount.sub(feeAmount));
        }
        else {
            super._transfer(from, to, amount);
        }
    }

    function toggleFeeless(address addr_) external onlyOwner {
        feeless[addr_] = !feeless[addr_];
    }

    function changeRebalanceInterval(uint256 interval_) external onlyOwner {
        rebalanceInterval = interval_;
    }


    function changeFeeDivisor(uint16 feeDivisor_) external onlyOwner {
        require(feeDivisor_ >= 10, "Must not be greater than 10% total fee");
        feeDivisor = feeDivisor_;
    }

    function changeCallerRewardDivisor(uint16 callerRewardDivisor_) external onlyOwner {
        require(callerRewardDivisor_ >= 10, "Must not be greater than 10% total");
        callerRewardDivisor = callerRewardDivisor_;
    }
    
    function changeMinRebalancerAmount(uint256 minimumRebalanceAmount_) external onlyOwner {
        require(minimumRebalanceAmount_ >= 1, "Must be greater than 1");
        minimumRebalanceAmount = minimumRebalanceAmount_;
    }

    function changeRebalalncerDivisor(uint16 rebalancerDivisor_) external onlyOwner {
        require(rebalancerDivisor_ >= 10, "Must not be greater than 10% total");
        rebalancerDivisor = rebalancerDivisor_;
    }

    function setUniRouter(address uniRouter_) external onlyOwner {
        uniRouter = uniRouter_;
        uniFactory = IUniswapV2Router02(uniRouter).factory();
        WETH = IUniswapV2Router02(uniRouter).WETH();
        uniPair = IUniswapV2Factory(uniFactory).getPair(WETH, address(this));
        if( uniPair == address(0))
            uniPair = IUniswapV2Factory(uniFactory).createPair(address(this), WETH);
    }

    function setRenaRouter(address renaRouter_) external onlyOwner {
        renaRouter = renaRouter_;
        renaFactory = IUniswapV2Router02(renaRouter).factory();
        feeless[renaRouter_] = true;
    }
    

    function setRebalancer(address payable rebalancer_) external onlyOwner {
        rebalancer = rebalancer_;
        feeless[rebalancer_] = true;
    }

    function setClaim(address claim_) external onlyOwner {
        claim = claim_;
        feeless[claim_] = true;
    }

    function setlpStaking(address lpStaking_) external onlyOwner {
        lpStaking = lpStaking_;
        feeless[lpStaking_] = true;
    }

    function setFeeDistributor(address payable feeDistributor_) external onlyOwner {
        feeDistributor = feeDistributor_;
        feeless[feeDistributor_] = true;
    }

    function rebalance() external nonReentrant {
        require(balanceOf(msg.sender) > minimumRebalanceAmount, "You aren't part of the syndicate");
        require(block.timestamp > lastRebalance + rebalanceInterval, "Too Soon");
        lastRebalance = block.timestamp;

        IRebalancer(rebalancer).rebalance(callerRewardDivisor, rebalancerDivisor);
    }
}