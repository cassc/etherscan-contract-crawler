// SPDX-License-Identifier: MIT

/*
======================================
$IMGBOT
ImgBot AI
THE ONLY AI IMAGE GENERATION TOOL YOU’LL EVER NEED
Powered by state-of-the-art deep learning models, IMGBOT utilizes a vast dataset of eclectic images to generate stunning visuals.
- https://imgbotai.com/
======================================
*/
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ImgBot is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 10 ** 18;

    uint256 public sellFee;
    uint256 public buyFee;

    address private deployer;

    address public pair;
    address public feeWallet;

    uint256 public maxWallet = (TOTAL_SUPPLY * 1) / 100;

    address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool public tradingEnabled = false;
    bool public feeLocked = false;

    mapping(address => bool) private whitelisted;

    constructor() ERC20("ImgBot AI", "IMGBOT") {
        _mint(msg.sender, TOTAL_SUPPLY);

        pair = IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory())
            .createPair(
                address(this),
                IUniswapV2Router02(uniswapRouter).WETH()
            );

        deployer = msg.sender;

        buyFee = 1000;
        sellFee = 1000;

        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;
    }

    function setFee(
        uint256 _newBuyFee,
        uint256 _newSellFee
    ) external onlyOwner {
        require(!feeLocked, "fee-locked");
        require(_newBuyFee <= 1000, "buy-fee-too-high");
        require(_newSellFee <= 1000, "sell-fee-too-high");

        buyFee = _newBuyFee;
        sellFee = _newSellFee;
    }

    function lockFee() external onlyOwner {
        feeLocked = true;
    }

    function setFeeWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "address-is-0");
        whitelisted[_wallet] = true;
        feeWallet = _wallet;
    }

    function startTrading() external onlyOwner {
        require(!tradingEnabled, "trading-already-enabled");
        tradingEnabled = true;
    }

    function removeLimits() external onlyOwner {
        maxWallet = TOTAL_SUPPLY;
    }

    function sweep(address _token) external {
        require(_token != address(this), "cannot-sweep-token");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(deployer, balance);
    }

    function sweepEth() external {
        uint256 balance = address(this).balance;
        payable(deployer).transfer(balance);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (sender != address(0) && recipient != address(0)) {
            require(
                tradingEnabled || whitelisted[sender],
                "trading-not-enabled"
            );

            if (sender == pair && !whitelisted[recipient]) {
                // sell
                uint256 fee = (amount * sellFee) / 10000;
                super._transfer(sender, feeWallet, fee);

                amount -= fee;
            } else if (recipient == pair && !whitelisted[sender]) {
                // buy
                uint256 fee = (amount * buyFee) / 10000;
                super._transfer(sender, feeWallet, fee);
                amount -= fee;
            }
        }
        if (recipient != pair && !whitelisted[recipient]) {
            require(
                amount + balanceOf(recipient) <= maxWallet,
                "max-wallet-reached"
            );
        }
        super._transfer(sender, recipient, amount);
    }
}