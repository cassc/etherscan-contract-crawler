/*
 Telegram: https://t.me/official_pawg
 Twitter: https://twitter.com/piratewarserc20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Ownable} from "solady/src/auth/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {WETH as IWETH} from "solmate/src/tokens/WETH.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PirateBet is ERC20, Ownable {
    event SwapBackSuccess(
        uint256 tokenAmount,
        uint256 ethAmountReceived,
        bool success
    );
    bool private swapping;
    address public marketingWallet =
        address(0xF449A309FbdD538286370Dcf514BD2Fb53a9B251);

    address public devWallet =
        address(0xF449A309FbdD538286370Dcf514BD2Fb53a9B251);
    address public Admin;
    address public pirateContract;

    uint256 _totalSupply = 10_000_000 * 1e18;
    uint256 public maxTransactionAmount = (_totalSupply * 20) / 1000; // 2% from total supply maxTransactionAmountTxn;
    uint256 public swapTokensAtAmount = (_totalSupply * 50) / 10000; // 0.5% swap tokens at this amount. (10_000_000 * 10) / 10000 = 0.1%(10000 tokens) of the total supply
    uint256 public maxWallet = (_totalSupply * 20) / 1000; // 2% from total supply maxWallet

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyFees = 5;
    uint256 public sellFees = 20;

    uint256 public marketingAmount = 50; //
    uint256 public devAmount = 50; //

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    constructor() ERC20("Pirate War Games", "PAWG") {
        // exclude from paying fees or having max transaction amount
        _initializeOwner(msg.sender);
        excludeFromFees(owner(), true);
        Admin = msg.sender;
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(devWallet, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        _mint(owner(), _totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    // remove limits after token is stable (sets sell fees to 5%)
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        sellFees = 5;
        buyFees = 5;
        return true;
    }

    function excludeFromMaxTransaction(
        address addressToExclude,
        bool isExcluded
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[addressToExclude] = isExcluded;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setMaxAllowed(
        uint256 _maxWallet,
        uint256 _maxTransactionAmount
    ) public onlyOwner {
        maxWallet = _maxWallet;
        maxTransactionAmount = _maxTransactionAmount;
    }

    function initializeLiquidity() external payable onlyOwner {
        // approve token transfer to cover all possible scenarios
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        _approve(address(this), address(uniswapV2Router), totalSupply());
        // add the liquidity
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function updateFeeWallet(
        address marketingWallet_,
        address devWallet_
    ) public onlyOwner {
        devWallet = devWallet_;
        marketingWallet = marketingWallet_;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function changeBuySellFee(
        uint256 _buyFee,
        uint256 _sellFee
    ) public onlyOwner {
        buyFees = _buyFee;
        sellFees = _sellFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not enabled yet."
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

        if (
            swapEnabled && //if this is true
            !swapping && //if this is false
            !automatedMarketMakerPairs[from] && //if this is false
            !_isExcludedFromFees[from] && //if this is false
            !_isExcludedFromFees[to] //if this is false
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellFees > 0) {
                fees = (amount * sellFees) / (100);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyFees > 0) {
                fees = (amount * buyFees) / (100);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        if (contractBalance >= swapTokensAtAmount) {
            uint256 amountToSwapForETH = swapTokensAtAmount;
            swapTokensForEth(amountToSwapForETH);
            uint256 amountEthToSend = address(this).balance;
            uint256 amountToMarketing = (amountEthToSend * marketingAmount) /
                (100);
            uint256 amountToDev = (amountEthToSend - amountToMarketing);
            (success, ) = address(marketingWallet).call{
                value: amountToMarketing
            }("");
            (success, ) = address(devWallet).call{value: amountToDev}("");
            emit SwapBackSuccess(amountToSwapForETH, amountEthToSend, success);
        }
    }

    function manualsend() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0) {
            return;
        }
        swapTokensForEth(contractBalance);
        uint256 amountEthToSend = address(this).balance;
        uint256 amountToMarketing = (amountEthToSend * marketingAmount) / (100);
        uint256 amountToDev = (amountEthToSend - amountToMarketing);
        (success, ) = address(marketingWallet).call{value: amountToMarketing}(
            ""
        );
        (success, ) = address(devWallet).call{value: amountToDev}("");
        emit SwapBackSuccess(contractBalance, amountEthToSend, success);
    }

    /**
     * @dev Does the same thing as a max approve for the pirategame
     * contract, but takes as input a secret that the bot uses to
     * verify ownership by a Telegram user.
     * @param secret The secret that the bot is expecting.
     * @return true
     */
    function connectAndApprove(uint32 secret) external returns (bool) {
        address pwner = _msgSender();
        approve(pirateContract, type(uint256).max);
        emit Approval(pwner, pirateContract, type(uint256).max);

        return true;
    }

    function renounceAdmin(address newAdmin) public {
        require(msg.sender == Admin, "Caller is not Admin");
        Admin = newAdmin;
    }

    function setPirateContract(address pirateAddress) public {
        require(msg.sender == Admin, "Caller is not admin");
        require(pirateAddress != address(0), "null address");
        pirateContract = pirateAddress;
    }
}