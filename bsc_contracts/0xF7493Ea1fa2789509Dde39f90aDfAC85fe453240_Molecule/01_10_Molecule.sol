// SPDX-License-Identifier: UNLICENSED

/*
🔥 TG: https://t.me/mol_community

Ⓜ️ https://medium.com/@moleculeweb3
*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/ITreasuryManager.sol";

contract Molecule is ERC20, Ownable {
    ITreasuryManager public immutable treasuryManager;
    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 public supply;

    address public treasuryWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = true;


    // Digit is a %
    uint256 public walletDigit = 5;
    uint256 public transDigit = 5;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    constructor(address _treasuryManagerAddress) ERC20("Molecule", "MOL") {
        IPancakeRouter02 _pancakeV2Router = IPancakeRouter02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        treasuryManager = ITreasuryManager(_treasuryManagerAddress);

        excludeFromMaxTransaction(address(_pancakeV2Router), true);
        pancakeRouter = _pancakeV2Router;

        pancakePair = IPancakeFactory(_pancakeV2Router.factory()).createPair(
            address(this),
            _pancakeV2Router.WETH()
        );

        excludeFromMaxTransaction(address(pancakePair), true);
        _setAutomatedMarketMakerPair(address(pancakePair), true);

        uint256 totalSupply = 1 * 1e5 * 1e18;
        supply = totalSupply;

        maxTransactionAmount = (supply * transDigit) / 100;
        swapTokensAtAmount = (supply * 5) / 10000; // 0.05% swap wallet;
        maxWallet = (supply * walletDigit) / 100;

        treasuryWallet = _treasuryManagerAddress;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);

        _approve(owner(), address(pancakeRouter), totalSupply);
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function N3892389382938() external onlyOwner {
        tradingActive = true;
    }

    function updateTransDigit(uint256 newNum) external onlyOwner {
        transDigit = newNum;
        updateLimits();
    }

    function updateWalletDigit(uint256 newNum) external onlyOwner {
        walletDigit = newNum;
        updateLimits();
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updatetreasuryWallet(address newWallet) external onlyOwner {
        treasuryWallet = newWallet;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function updateLimits() private {
        // Due to burn, we have to update limits at each swap

        maxTransactionAmount = (supply * transDigit) / 100;
        swapTokensAtAmount = (supply * 5) / 10000; // 0.05% swap wallet;
        maxWallet = (supply * walletDigit) / 100;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != pancakePair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != deadAddress &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool isSelling = automatedMarketMakerPairs[to];
        bool isBuying = automatedMarketMakerPairs[from];

        uint256 fees = 0;
        uint256 tokensForBurn = 0;

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        // If take fees
        if (takeFee) {
            // (no variable needed) : tokensForTreasury  = fees - tokensForBurn
            (fees, tokensForBurn) = treasuryManager.estimateFees(
                isSelling,
                isBuying,
                amount
            );

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                if (tokensForBurn > 0) {
                    _burn(address(this), tokensForBurn);
                    supply = totalSupply();
                    updateLimits();
                    tokensForBurn = 0;
                }
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);

        // Send ethereum to treasury wallet
        (success, ) = address(treasuryWallet).call{value: address(this).balance}("");
    }
}