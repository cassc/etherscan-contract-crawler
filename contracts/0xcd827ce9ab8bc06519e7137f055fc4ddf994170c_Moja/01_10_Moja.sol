pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Moja is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private TOTAL_SUPPLY = 1000000 * 1e18;
    uint256 public maxTransactionAmount;
    uint256 public maxWalletAmount;
    uint256 public marketingFeePercent;

    address private marketingWallet;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public excludedMaxTransactionAmount;

    bool private inSwap = false;
    bool public tradingActive = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20("Moja", "Moja") {
        prepareUniswap();

        marketingWallet = address(0x14da9dE87aB0A647a08Ab30fDA9DDE385bB3992d);

        maxTransactionAmount = TOTAL_SUPPLY / 100 + 1; // Max 1% from total supply
        maxWalletAmount = maxTransactionAmount * 5; // Max 5% from total supply
        marketingFeePercent = 5; // 5% for marketing

        excludedFromFees[owner()] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketingWallet] = true;
        excludedMaxTransactionAmount[owner()] = true;
        excludedMaxTransactionAmount[address(this)] = true;
        excludedMaxTransactionAmount[marketingWallet] = true;

        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function prepareUniswap() private {
        address routerAddress = address(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        _approve(address(this), routerAddress, type(uint256).max);

        excludedFromFees[address(uniswapV2Router)] = true;
        excludedFromFees[address(uniswapV2Pair)] = true;
        excludedMaxTransactionAmount[address(uniswapV2Router)] = true;
        excludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
    }

    function _transfer( address from, address to, uint256 amount ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingActive, "Trading is not active.");
        require(amount <= balanceOf(from), "You are trying to transfer more than your balance");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
		require(
			excludedMaxTransactionAmount[from] || excludedMaxTransactionAmount[to] || amount <= maxTransactionAmount, 
			'Exceeds the maxTransactionAmount.'
		);
        if (inSwap) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 newAmount = amount;
        if (!excludedFromFees[from] && !excludedFromFees[to]) {
            uint256 marketingFee = amount * marketingFeePercent / 100;
            newAmount = amount - marketingFee;
            super._transfer(from, address(this), marketingFee);
		}

		super._transfer(from, to, newAmount);
    }

    function enableTrading() public onlyOwner {
        tradingActive = true;
    }

    function removeLimits() public onlyOwner {
        maxTransactionAmount = TOTAL_SUPPLY;
        maxWalletAmount = TOTAL_SUPPLY;
    }

	function setExcludedFromFees(address _address, bool value) public onlyOwner {
		excludedFromFees[_address] = value;
	}

	function setExcludedMaxTransactionAmount(address _address, bool value) public onlyOwner {
		excludedMaxTransactionAmount[_address] = value;
	}

	function mintMarketingToken () public lockTheSwap onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
		super._transfer(address(this), marketingWallet, contractTokenBalance);
	}
}