// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface PlanB {
    function mint(address to,uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approveToMinter(address minter, address to, uint256 amount) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface MintPlanB {
    function deposit(address _address, uint _total, uint256 _nextReward, uint256 _reward) external;
}

contract MintPortal is Ownable {
    using SafeMath for uint256;
    PlanB token;
    MintPlanB mints;
    uint256 maxMintFee = 1 ether;
    uint256 multX = 1000000;
    uint256 public total = 0;
    uint8 mintOpen = 0;
    address mintsAddress = address(0);
    uint lockTime = 21 days;

    mapping(address => uint8) public register;

    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address dead = 0x000000000000000000000000000000000000dEaD;
    address dao = 0x41cf7c14d1D16974dfE13371656b1356D606F77C;
    address public uniswapV2Pair = address(0);
    
    constructor(address _address) {
        token = PlanB(_address);
        mintOpen = 1;
    }

    modifier onlyWhenMintOpen() {
        require(mintOpen == 1, "Mint is now closed");
        _;
    }

    modifier alreadyMinted() {
        require(register[msg.sender] == 0, "You already minted");
        _;
    }

    modifier MintContractIsNotNull() {
        require(mintsAddress != address(0), "Contract is not set yet.");
        _;
    }

    function addMintAddress(address _mints) public onlyOwner {
        mints = MintPlanB(_mints);
        mintsAddress = _mints;
    }

    function mint() public payable MintContractIsNotNull alreadyMinted onlyWhenMintOpen {
        require(msg.value <= maxMintFee, "Fee is not correct");
        require(msg.value > 0, "Mint Fee can not be 0");
        uint256 toMint = msg.value * multX;
        uint256 uniswap = toMint.mul(25).div(100);
        uint256 daoAmount = toMint.mul(15).div(100);
        uint256 lock = block.timestamp + lockTime;
        uint256 reward = toMint - uniswap - daoAmount;
        uint256 splitRewards = reward.div(6);
        uint256 rewardNow = splitRewards;
        mints.deposit(msg.sender, reward - splitRewards, lock, splitRewards);
        token.mint(address(this),  uniswap);
        token.mint(dao, daoAmount);
        token.mint(msg.sender, rewardNow);
        total += toMint;
        register[msg.sender] = 1;
    }

    function approve() external onlyOwner {
        token.approveToMinter(address(this), address(uniswapV2Router), total);
    }

    function createUniswapPoolAndInitilizeLiquidity() external onlyOwner {
        require(uniswapV2Pair == address(0),"UniswapV2Pair has already been set");
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(token), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(token),
            token.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp);
        mintOpen = 0;
    }

    function burnUniswapPool() external onlyOwner {
        // Burn and lock forever. YOLO!
        uint liquidity = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).transfer(dead, liquidity);
    }

    receive() external payable {}
}