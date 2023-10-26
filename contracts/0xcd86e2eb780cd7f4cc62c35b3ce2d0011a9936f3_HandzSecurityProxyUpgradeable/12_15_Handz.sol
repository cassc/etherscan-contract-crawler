// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { ERC20 } from "./ERC20.sol";

import { IUniswapV2Factory } from "./uniswap/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "./uniswap/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "./uniswap/IUniswapV2Router02.sol";

contract Handz is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    //address data-sets
    address public autoBuyAddress =
        address(0x099f8d9e004cE139c6F46572ea99c0DB71889A78);
    address public constant deadAddress = address(0xdead);
    address public teamWallet;
    address public uniswapV2Pair;

    //bool data-sets
    bool public isLimitActive;
    bool public isTradingOpen;
    bool public swapEnabled;
    bool private swapping;

    //int data-sets
    uint256 public _buyAutobuyFee = 3;
    uint256 public _buyLpFee = 2;
    uint256 public _buyTeamFee = 0;
    uint256 public buyTotalFees = _buyLpFee + _buyTeamFee + _buyAutobuyFee;

    uint256 public _sellAutobuyFee = 3;
    uint256 public _sellLpFee = 1;
    uint256 public _sellTeamFee = 1;
    uint256 public sellTotalFees = _sellLpFee + _sellTeamFee + _sellAutobuyFee;

    uint256 public _autoBuyTokenShare;
    uint256 public _LpTokenShare;
    uint256 public _teamTokenShare;

    uint256 public teamAllocate;
    uint256 public teamAllocateReleaseTime;
    uint256 constant teamAllocatePeriod = 365 days;

    uint256 public txMaxperWallet;
    uint256 public maxTokenPerWallet;
    uint256 public swapTokensAtAmount;

    //mapping data-sets
    mapping(address => bool) blacklisted;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isTxMaxExcluded;
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("HANDZ", "HANDZ") {
        uint256 totalSupply = 100_000_000 * 1e18;

        teamAllocate = totalSupply / 10;
        teamAllocateReleaseTime = block.timestamp + teamAllocatePeriod;

        uint256 ownerTokens = totalSupply - teamAllocate;

        _mint(msg.sender, ownerTokens);
    }

    // dataset
    function initContract() external onlyOwner {
        //TESTNET Router
        ///IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008);

        //DEX data-sets  //MAINNET
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        isLimitActive = true;
        isTradingOpen = false;
        swapEnabled = false;

        txMaxperWallet = 1_000_000 * 1e18;
        maxTokenPerWallet = 1_000_000 * 1e18;
        swapTokensAtAmount = (this.totalSupply() * 5) / 10000;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _excludeFromMaxTx(owner(), true);
        _excludeFromMaxTx(address(this), true);
        _excludeFromMaxTx(address(0xdead), true);
        _excludeFromMaxTx(address(uniswapV2Router), true);
        _excludeFromMaxTx(address(uniswapV2Pair), true);
    }

    function launchHandz() external onlyOwner {
        isTradingOpen = true;
        swapEnabled = true;
    }

    function setLimit() external onlyOwner returns (bool) {
        isLimitActive = false;
        return true;
    }

    function setDegenMaxWallet(uint256 amt) external onlyOwner {
        require(
            amt >= ((totalSupply() * 10) / 1000) / 1e18,
            "Max number must be bigger than 1.0%"
        );
        maxTokenPerWallet = amt * (10**18);
    }

    function setTxMax(uint256 amt) external onlyOwner {
        require(
            amt >= ((totalSupply() * 5) / 1000) / 1e18,
            "must be bigger than 0.5%"
        );
        txMaxperWallet = amt * (10**18);
    }

    function setSwapLimit(uint256 amt) external onlyOwner returns (bool) {
        require(
            amt >= (totalSupply() * 1) / 100000,
            "Swap limit must be higher than 0.001% total supply."
        );
        require(
            amt <= (totalSupply() * 5) / 1000,
            "Swap limit cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = amt;
        return true;
    }

    //setswap action
    function setSwapEnabled(bool action) external onlyOwner {
        swapEnabled = action;
    }

    function _excludeFromMaxTx(address newAdd, bool action) public onlyOwner {
        _isTxMaxExcluded[newAdd] = action;
    }

    function setBuyFees(
        uint256 _autoFee,
        uint256 _lpFee,
        uint256 _teamFee
    ) external onlyOwner {
        _buyAutobuyFee = _autoFee;
        _buyLpFee = _lpFee;
        _buyTeamFee = _teamFee;
        buyTotalFees = _buyAutobuyFee + _buyLpFee + _buyTeamFee;
        require(buyTotalFees <= 5, "Buy fee max should 5%");
    }

    function setSellFees(
        uint256 _autoFee,
        uint256 _lpFee,
        uint256 _teamFee
    ) external onlyOwner {
        _sellAutobuyFee = _autoFee;
        _sellLpFee = _lpFee;
        _sellTeamFee = _teamFee;
        sellTotalFees = _sellAutobuyFee + _sellLpFee + _sellTeamFee;
        require(sellTotalFees <= 5, "Sell Max must be 5%");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setTeamAddress(address newAdd) external onlyOwner {
        teamWallet = newAdd;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from], "Sender blacklisted");
        require(!blacklisted[to], "Receiver blacklisted");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (isLimitActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!isTradingOpen) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // buying
                if (automatedMarketMakerPairs[from] && !_isTxMaxExcluded[to]) {
                    require(
                        amount <= txMaxperWallet,
                        "Buy transfer amount exceeds the txMaxperWallet."
                    );
                    require(
                        amount + balanceOf(to) <= maxTokenPerWallet,
                        "Max wallet exceeded"
                    );
                }
                //selling
                else if (
                    automatedMarketMakerPairs[to] && !_isTxMaxExcluded[from]
                ) {
                    require(
                        amount <= txMaxperWallet,
                        "Sell transfer amount exceeds the txMaxperWallet."
                    );
                } else if (!_isTxMaxExcluded[to]) {
                    require(
                        amount + balanceOf(to) <= maxTokenPerWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            SwapNow();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                _LpTokenShare += (fees * _sellLpFee) / sellTotalFees;
                _teamTokenShare += (fees * _sellTeamFee) / sellTotalFees;
                _autoBuyTokenShare += (fees * _sellAutobuyFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                _LpTokenShare += (fees * _buyLpFee) / buyTotalFees;
                _teamTokenShare += (fees * _buyTeamFee) / buyTotalFees;
                _autoBuyTokenShare += (fees * _buyAutobuyFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _autoBuy(uint256 ethAmt) private {
        if (ethAmt > 0) {
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = autoBuyAddress;
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: ethAmt
            }(0, path, teamWallet, block.timestamp);
        }
    }

    function SwapNow() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _LpTokenShare +
            _autoBuyTokenShare +
            _teamTokenShare;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * _LpTokenShare) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForTeam = ethBalance.mul(_teamTokenShare).div(
            totalTokensToSwap - (_LpTokenShare / 2)
        );
        uint256 ethForBuyback = ethBalance.mul(_autoBuyTokenShare).div(
            totalTokensToSwap - (_LpTokenShare / 2)
        );

        uint256 ethForLiquidity = ethBalance - ethForBuyback - ethForTeam;

        _LpTokenShare = 0;
        _autoBuyTokenShare = 0;
        _teamTokenShare = 0;

        (success, ) = address(teamWallet).call{value: ethForTeam}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                _LpTokenShare
            );
        }
        _autoBuy(ethForBuyback);
    }

    function changeUniswapRouterv2(address newAdd) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newAdd);
    }

    function changeAutoBuyAddress(address newAdd) public onlyOwner {
        autoBuyAddress = address(newAdd);
    }

    function blacklist(address newAdd) public onlyOwner {
        blacklisted[newAdd] = true;
    }

    function unblacklist(address newAdd) public onlyOwner {
        blacklisted[newAdd] = false;
    }

    function withdrawTeamAllocate() external {
        require(teamAllocateReleaseTime <= block.timestamp, "Tokens are locked");
        
        _mint(teamWallet, teamAllocate);
        
        teamAllocate = 0;
    }

    function withdrawEth(address newAdd) external onlyOwner {
        (bool success, ) = newAdd.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {}
}