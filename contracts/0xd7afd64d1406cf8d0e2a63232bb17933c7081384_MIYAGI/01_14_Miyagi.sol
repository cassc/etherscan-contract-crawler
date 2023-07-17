// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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

contract MIYAGI is Context, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 private maxSupply;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public miyagiV1;

    mapping(address => bool) public pair;
    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public claimed;

    uint256 private start;
    uint256 private maxWalletTimer;
    uint256 private started;
    uint256 private maxWallet;
    uint256 private maxTransaction;
    uint256 private supply;
    uint256 private swapTokensAtAmount;
    uint256 private taxOnTaxOffCounter;
    uint256 private taxOnTaxOffTransactions;

    uint256 public buyTax;
    uint256 public sellTax;

    bool public starting;
    bool public swapping;
    bool public increaseBuyTax;

    address payable teamWallet;
    address payable marketingWallet;

    constructor(address payable _teamWallet, address payable _marketingWallet, uint256 _maxWalletTimer, address _miyagiV1, uint256 _supply) ERC20 ("MIYAGI", "MIYAGI") payable {

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        maxSupply = 5 * 10 ** 8 * 10 ** decimals();
        supply = _supply;

        starting = true;
        increaseBuyTax = false;
        buyTax = 20;
        sellTax = 0;
        maxWallet = (maxSupply * 200) / 10000; // Max wallet 2% of Supply
        maxTransaction = (maxSupply * 100) / 10000; // Max transaction 1% of Supply
        maxWalletTimer = maxWalletTimer;
        taxOnTaxOffCounter = 0;
        taxOnTaxOffTransactions = 5;
        uint256 _tokensForMarketing = ((maxSupply * 5) / 100);

        teamWallet = payable(_teamWallet);
        marketingWallet = payable(_marketingWallet);
        miyagiV1 = _miyagiV1;

        swapTokensAtAmount = ((maxSupply * 25) / 10000);

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;

        _mint(owner(), supply);
        _mint(teamWallet, _tokensForMarketing);
        _mint(address(this), (maxSupply - (supply + _tokensForMarketing)));
    }

    receive() external payable {

    }

    function updatetaxOnTaxOffTransactions(uint256 _taxOnTaxOffTransactions) external onlyOwner {
        taxOnTaxOffTransactions = _taxOnTaxOffTransactions;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount * 10 ** decimals());
    }

    function addPair(address _uniswapPair) external onlyOwner {

        pair[_uniswapPair] = true;
        uniswapV2Pair = _uniswapPair;

        start = block.number;
        starting = false;
        started = block.timestamp;
    }

    function updateSwapTokensAtAmount(uint256 swapPercentDivisibleBy10000) external onlyOwner {
        swapTokensAtAmount = ((totalSupply() * swapPercentDivisibleBy10000) / 10000);
    }

    function updateTax(uint256 _buyTax, uint256 _sellTax, bool _increaseBuyTax) external onlyOwner {
        buyTax = _buyTax;
        sellTax = _sellTax;

        increaseBuyTax = _increaseBuyTax;
        taxOnTaxOffCounter = 0;
    }

    //function to update buy and sell fees
    function taxOnTaxOff() internal {
        if(sellTax == 0) {
            increaseBuyTax = false;
        } else if(buyTax == 0) {
            increaseBuyTax = true;
        }
        
        if(increaseBuyTax) {
            buyTax ++;
            sellTax --;
        } else {
            buyTax --;
            sellTax ++;
        }
        taxOnTaxOffCounter = 0;
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
        taxOnTaxOffCounter ++;

        if((block.timestamp < (started + maxWalletTimer)) && to != address(0) && to != uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            uint256 balance = balanceOf(to);
            require(balance + amount <= maxWallet, "Transfer amount exceeds maximum wallet");
            require(amount <= maxTransaction, "Transfer amount exceeds maximum transaction");
        }

        if((block.timestamp < (started + maxWalletTimer)) && to != address(0) && to == uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            require(amount <= maxTransaction, "Transfer amount exceeds maximum transaction");
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if(canSwap && !swapping && pair[to] && from != address(uniswapV2Router) && from != owner() && to != owner() && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            
            swapping = true;
            
            swapTokensForEth();

            uint256 contractETHBalance = address(this).balance;

            (bool success, ) = address(teamWallet).call{value: ((contractETHBalance * 20) / 100)}("");
            require(success, "Failed to send taxes to team wallet");

            (success, ) = address(marketingWallet).call{value: address(this).balance}("");
            require(success, "Failed to send taxes to marketing wallet");

            swapping = false;
        }

        bool takeFee = !swapping;

         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        else if(!pair[to] && !pair[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        if(takeFee) {

            uint256 BuyFees = ((amount * buyTax) / 100);
            uint256 SellFees = ((amount * sellTax) / 100);

            // if sell
            if(pair[to] && sellTax > 0) {
                amount -= SellFees;
                super._transfer(from, address(this), SellFees);
                super._transfer(from, to, amount);
                if(taxOnTaxOffCounter > taxOnTaxOffTransactions) {
                    taxOnTaxOff();
                } 
            }

            // if buy transfer
            else if(pair[from] && buyTax > 0) {
                amount -= BuyFees;
                super._transfer(from, address(this), BuyFees);
                super._transfer(from, to, amount);

                if(taxOnTaxOffCounter > taxOnTaxOffTransactions) {
                    taxOnTaxOff();
                }
                }

            else {
                super._transfer(from, to, amount);

                if(taxOnTaxOffCounter > taxOnTaxOffTransactions) {
                    taxOnTaxOff();
                }
            }
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

    function migrate() public nonReentrant {
        require(!claimed[msg.sender], "V2 tokens already claimed");
        claimed[msg.sender] = true;
        uint256 _amount = ERC20(miyagiV1).balanceOf(msg.sender);
        require(_amount > 0, "No v1 tokens to swap");
        require(balanceOf(msg.sender) + _amount <= maxWallet, "Cannot exceed max wallet");

        if(ERC20(miyagiV1).balanceOf(msg.sender) > 0) {
            ERC20(miyagiV1).approve(address(this), _amount);
            bool success = ERC20(miyagiV1).transferFrom(msg.sender, address(owner()), ERC20(miyagiV1).balanceOf(msg.sender));
            require(success, "Failed to send v1 tokens");
        }

        super._transfer(address(this), msg.sender, _amount);
    }

    function withdrawRemainingTokens() external onlyOwner {
        uint256 _amount = balanceOf(address(this));

        super._transfer(address(this), owner(), _amount);
    }

}