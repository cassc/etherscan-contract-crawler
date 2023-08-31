// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SHARX is Context, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 private maxSupply;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) public pair;
    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public earlyBuyer;

    uint256 private start;
    uint256 private maxWalletTimer;
    uint256 private started;
    uint256 private maxWallet;
    uint256 private supply;
    uint256 private swapTokensAtAmount;

    uint256 public buyTax;
    uint256 public sellTax;

    bool public starting;
    bool public swapping;
    bool public botCheck;

    address payable teamWallet;
    address payable marketingWallet;
    address[3] public devWallets;

    constructor(address payable _teamWallet, address payable _marketingWallet, address payable _dev, address payable _devTemp1, address payable _devTemp2, uint256 _maxWalletTimer, uint256 _bridgeSupply, address _bridgeAddress) ERC20 ("RaidSharksBot", "SHARX") payable {

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        maxSupply = 5 * 10 ** 8 * 10 ** decimals();
        supply = maxSupply - _bridgeSupply;

        starting = true;
        botCheck = true;
        buyTax = 5;
        sellTax = 5;
        maxWallet = (maxSupply * 69) / 100000; // Max wallet .069% of Supply
        maxWalletTimer = block.timestamp + maxWalletTimer;

        teamWallet = payable(_teamWallet);
        marketingWallet = payable(_marketingWallet);
        devWallets[0] = payable(_dev);
        devWallets[1] = payable(_devTemp1);
        devWallets[2] = payable(_devTemp2);

        swapTokensAtAmount = ((maxSupply * 25) / 10000);

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;

        _mint(owner(), supply);
        _mint(_bridgeAddress, _bridgeSupply);
    }

    receive() external payable {

    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount * 10 ** decimals());
    }

    function addPair(address _uniswapPair) external onlyOwner {

        pair[_uniswapPair] = true;
        uniswapV2Pair = _uniswapPair;

        start = block.number;
        started = block.timestamp;
        starting = false;
    }

    function removeAddressFromEarlyBuyer(address toRemove) external onlyOwner {
        require(earlyBuyer[toRemove], "Address not marked as an early buyer");

        earlyBuyer[toRemove] = false;
    }

    function updateSwapTokensAtAmount(uint256 swapPercentDivisibleBy10000) external onlyOwner {
        swapTokensAtAmount = ((totalSupply() * swapPercentDivisibleBy10000) / 10000);
    }

    function updateTaxes(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(_buyTax <= 5 && _sellTax <= 5, "Tax cannot be more than 10%");
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(starting) {
            require(from == owner() || to == owner(), "Trading is not yet enabled");
        }
        uint256 current = block.number;

        if((block.timestamp < (started + maxWalletTimer)) && to != address(0) && to != uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            uint256 balance = balanceOf(to);
            require(balance + amount <= maxWallet, "Transfer amount exceeds maximum wallet");
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if(canSwap && !swapping && pair[to] && from != address(uniswapV2Router) && from != owner() && to != owner() && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            
            swapping = true;
            bool success;
            
            swapTokensForEth();

            uint256 contractETHBalance = address(this).balance;

            // pay 1% of the taxes to 2 separate dev wallets for 24 hours from addPair being called
            if(block.timestamp < (started + 1 days)) {
                uint256 devETHBalance = ((contractETHBalance * 20) / 100);
                contractETHBalance -= devETHBalance;
                (success, ) = address(devWallets[1]).call{value: (devETHBalance / 2)}("");
                require(success, "Failed to send taxes to dev wallet 1");
                (success, ) = address(devWallets[2]).call{value: (devETHBalance / 2)}("");
                require(success, "Failed to send taxes to dev wallet 2");
            } else {
                (success, ) = address(marketingWallet).call{value: (contractETHBalance * 20) / 100}("");
                require(success, "Failed to send taxes to marketing wallet");
            }

            (success, ) = address(teamWallet).call{value: ((contractETHBalance * 40) / 100)}("");
            require(success, "Failed to send taxes to team wallet");

            (success, ) = address(devWallets[0]).call{value: ((contractETHBalance * 40) / 100)}("");
                require(success, "Failed to send taxes to dev wallet");

            swapping = false;
        }

        bool takeFee = !swapping;

         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        else if(!pair[to] && !pair[from]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        if(takeFee) {

            uint256 BuyFees = ((amount * buyTax) / 100);
            uint256 SellFees = ((amount * sellTax) / 100);

            // auto blacklist first 5 blocks, 50% buy tax for first 1 minute, 70% sell tax for first 3 minutes
            if(botCheck || earlyBuyer[to] || earlyBuyer[from]) {
                pair[to] ? checkForBots(from) : checkForBots(to);
                SellFees = ((amount * 20) / 100);
                BuyFees = ((amount * 20) / 100);
            }

            // if sell
            if(pair[to] && sellTax > 0) {
                amount -= SellFees;
                super._transfer(from, address(this), SellFees);
                super._transfer(from, to, amount);
            }

            // if buy transfer
            else if(pair[from] && buyTax > 0) {
                amount -= BuyFees;
                super._transfer(from, address(this), BuyFees);
                super._transfer(from, to, amount);
                }

            else {
                super._transfer(from, to, amount);
            }
        }
    }

    // marks any buys within the first 5 blocks as early buyers, permanently taxing them at a higher tax rate
    function checkForBots(address _address) internal {
        if(block.number < (start + 5) && !pair[_address]) {
            if(earlyBuyer[_address]) {
                return;
            }
            earlyBuyer[_address] = true;
            return;
        } else if(botCheck && !pair[_address]){
            botCheck = false;
            maxWallet = (maxSupply * 150) / 10000; // Max wallet 1.5% of Supply
            return;
        } else {
            return;
        }
    }

    function swapTokensForEth() private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), swapTokensAtAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapTokensAtAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

}