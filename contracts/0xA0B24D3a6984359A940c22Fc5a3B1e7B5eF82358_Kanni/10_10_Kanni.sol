// SPDX-License-Identifier: AGPL-3.0-or-later

/*

https://t.me/KanniEntry

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";


contract Kanni is ERC20, Ownable {
    using SafeMath for uint256;

    // allow to exclude address from fees or/and max txs
    mapping(address => bool) private _excludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // fees
    uint256 public buyFees = 3;
    uint256 public sellFees = 3;

    // security (% of the supply)
    uint256 public maxWalletPercent = 2;
    uint256 public maxTxSupply = 2;
    uint256 public blockDelay = 5;
    uint256 public maxWallet;
    uint256 public maxTx;

    // uniswap
    IUniswapV2Router02 public immutable uniRouter;
    address public immutable uniPair;
    mapping(address => bool) public LPs;

    bool public tradingOpen = false;
    mapping(address => uint256) private _accountTransferTimestamp;
    bool private swapping;

    uint256 public supply;
    uint256 public canSwapTokens;

    address public marketingWallet;

    constructor(address _uniRouterAddress) ERC20("Kanni", "KANNI") {
        uint256 totalSupply = 1 * 1e6 * 1e6; // 1,000,000
        supply = totalSupply;

        // Exclude owner, contract, dead and router from max txs and fees
        excludeFromFees(owner(), true);
        excludeFromMaxTx(owner(), true);

        excludeFromFees(address(this), true);
        excludeFromMaxTx(address(this), true);
       
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTx(address(0xdead), true);

        // UniV2 Router
        IUniswapV2Router02 _uniRouter = IUniswapV2Router02(_uniRouterAddress);
        excludeFromMaxTx(address(_uniRouter), true);
        uniRouter = _uniRouter;

        // UniV2 LP
        uniPair = IUniswapV2Factory(_uniRouter.factory()).createPair(address(this), _uniRouter.WETH());
        excludeFromMaxTx(address(uniPair), true);
        LPs[address(uniPair)] = true;

        // limits
        maxTx = (supply * maxTxSupply) / 100;
        canSwapTokens = (supply * 5) / 10000;
        maxWallet = (supply * maxWalletPercent) / 100;

        marketingWallet = owner();

        _approve(owner(), address(uniRouter), totalSupply);
        _mint(msg.sender, totalSupply);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _excludedFromFees[account];
    }

    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function updateLimitsPercent(uint256 _maxTx, uint256 _maxWallet) external onlyOwner {
        maxTxSupply = _maxTx;
        maxWalletPercent = _maxWallet;
        updateLimits();
    }

    function updateMarketingWallet(address _new) external onlyOwner {
        marketingWallet = _new;
    }

    function excludeFromMaxTx(address _account, bool _status) public onlyOwner {
        _isExcludedMaxTransactionAmount[_account] = _status;
    }

    function excludeFromFees(address _account, bool _status) public onlyOwner {
        _excludedFromFees[_account] = _status;
    }

    function updateBlockDelay(uint256 _new) external onlyOwner {
        blockDelay = _new;
    }

    function updateLimits() private {
        maxTx = (supply * maxTxSupply) / 100;
        canSwapTokens = (supply * 5) / 10000;
        maxWallet = (supply * maxWalletPercent) / 100;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(tradingOpen || _excludedFromFees[from] || _excludedFromFees[to], "Trading not open");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool buy = LPs[from];
        bool sell = LPs[to];

        // maxTx and maxWallet
        if (from != owner() && to != owner() && to != address(0xdead) && !swapping) {
            // to avoid massive buy
            if (to != owner() && to != address(uniRouter) && to != address(uniPair)) {
                require(_accountTransferTimestamp[tx.origin] < block.number, "One dex tx per block");
                _accountTransferTimestamp[tx.origin] = block.number + blockDelay;
            }
            if ((sell || buy) && !_isExcludedMaxTransactionAmount[from]) { // maxTx 
                require(amount <= maxTx, "Amount exceeds the maxTx");
            } 
            if(!sell && !_isExcludedMaxTransactionAmount[to]) { // maxWallet
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }
        
        // swap security
        bool canSwap = balanceOf(address(this)) >= canSwapTokens;
        if (canSwap && !swapping && !buy && !_excludedFromFees[from] && !_excludedFromFees[to]) {
            swapping = true;
            retrieveSwap();
            swapping = false;
        }

        // fees
        if (!swapping && !_excludedFromFees[from] && !_excludedFromFees[to]) {
            uint256 fees = 0;
            if (sell && sellFees > 0) {
                fees = amount.mul(sellFees).div(100);
            }
            else if (buy && buyFees > 0) {
                fees = amount.mul(buyFees).div(100);
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        // transfer
        super._transfer(from, to, amount);
    }

    /* ---- Swap ---- */

    function swapTokensToWETH(uint256 tokenAmount) private {
        // path : token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();

        _approve(address(this), address(uniRouter), tokenAmount);

        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function retrieveSwap() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }
        if (contractBalance > canSwapTokens * 20) {
            contractBalance = canSwapTokens * 20;
        }
        swapTokensToWETH(contractBalance);

        bool success;
        (success, ) = address(marketingWallet).call{value: address(this).balance}(""); // marketing fees
    }

    receive() external payable {} // core

}