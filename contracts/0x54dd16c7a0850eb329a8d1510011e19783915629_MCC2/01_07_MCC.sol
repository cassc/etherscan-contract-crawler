// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
Second time's the charm. 

Twitter: Twitter.com/MCCtwoPOINT0

Web: https://www.mcc20.tech/

TG: https://t.me/MCC2point0

*/

interface IPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract MCC2 is ERC20, Ownable {
   
    using SafeMath for uint256;
  
    IRouter public router;
    address public pair;

    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => uint256) private _rOwned;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;
    mapping(address => bool) public _isBot;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000000 * (10 ** 18);
    address public constant deadAddress = address(0xdead);

    uint256 private _tSupply;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;
    uint256 public TradingActiveBlock;

    bool private swapping;

    bool public limitsInEffect = true;
    bool public tradingActive = false;

    uint256 public buyTotalFees;
    uint256 public buyTreasuryFee = 0;
    uint256 public buyBurnFee = 0;
    uint256 public buyReflectionFee = 0;

    uint256 public sellTotalFees;
    uint256 public sellTreasuryFee = 0;
    uint256 public sellBurnFee = 0;
    uint256 public sellReflectionFee = 0;

    uint256 public tokensForTreasury;
    uint256 public tokensForBurn;
    uint256 public tokensForReflections;

    uint256 public walletDigit;
    uint256 public transDigit;
    uint256 public swapDigit;

  
    //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    constructor(address _Router) ERC20("MCC 2.0", "MCC2.0") {
        IRouter _router = IRouter(_Router);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(address(_pair), true);
        buyTotalFees = buyTreasuryFee + buyBurnFee + buyReflectionFee;
        sellTotalFees = sellTreasuryFee + sellBurnFee + sellReflectionFee;

        _rOwned[_msgSender()] = _rTotal;
        _tSupply = _tTotal;

        walletDigit = 20;
        transDigit = 20;
        swapDigit = 5;

        maxTransactionAmount = (_tSupply * transDigit) / 1000;
        swapTokensAtAmount = (_tSupply * swapDigit) / 10000; // 0.05% swap wallet;
        maxWallet = (_tSupply * walletDigit) / 1000; 

        // exclude from paying fees or having max transaction amount, max wallet amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTransaction(address(_router), true);
        excludeFromMaxTransaction(address(_pair), true);
        excludeFromMaxWallet(address(_pair), true);
        excludeFromMaxWallet(address(_router), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);

        _approve(owner(), address(_router), _tSupply);
        _mint(msg.sender, _tSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require(tradingActive != true);
        TradingActiveBlock = block.timestamp;
        tradingActive = true;
    }

    /// @param bot The bot address
    /// @param value "true" to blacklist, "false" to unblacklist
    function setBot(address bot, bool value) public onlyOwner {
        require(bot != address(router));
        require(bot != address(pair));
        require(_isBot[bot] != value);
        _isBot[bot] = value;
    }

    function setBulkBot(address[] memory bots, bool value) external onlyOwner {
        for (uint256 i; i < bots.length; i++) {
            _isBot[bots[i]] = value;
        }
    }

    // remove limits after token is stable
    function toggleLimits(bool state) external onlyOwner returns (bool) {
        require(state != limitsInEffect);
        limitsInEffect = state;
        return true;
    }

    function updateDigits(
        uint256 newTrans,
        uint256 newWall,
        uint256 NewswapDigit
    ) external onlyOwner {
        require(newTrans >= 5 && newWall >= 5, "0.5% is the lowest ");
        transDigit = newTrans;
        walletDigit = newWall;
        swapDigit = NewswapDigit;
        updateLimits();
    }

    function updateLimits() private {
        maxTransactionAmount = (_tSupply * transDigit) / 1000; // if transdigit is 10 its 1% if its 20 its 2%
        swapTokensAtAmount = (_tSupply * swapDigit) / 1000; // 0.05% swap wallet (5);
        maxWallet = (_tSupply * walletDigit) / 1000; // same applies for transdigit
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromMaxWallet(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxWalletAmount[updAds] = isEx;
    }

    function updateBuyFees(
        uint256 _treasuryFee,
        uint256 _burnFee,
        uint256 _reflectionFee
    ) external onlyOwner {
        buyTreasuryFee = _treasuryFee;
        buyBurnFee = _burnFee;
        buyReflectionFee = _reflectionFee;
        buyTotalFees = buyTreasuryFee + buyBurnFee + buyReflectionFee;
        require(buyTotalFees <= 250, "Must keep fees at 25% or less");
    }

    function updateSellFees(
        uint256 _treasuryFee,
        uint256 _burnFee,
        uint256 _reflectionFee
    ) external onlyOwner {
        sellTreasuryFee = _treasuryFee;
        sellBurnFee = _burnFee;
        sellReflectionFee = _reflectionFee;
        sellTotalFees = sellTreasuryFee + sellBurnFee + sellReflectionFee;
        require(sellTotalFees <= 250, "Must keep fees at 25% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(
        address Pair,
        bool value
    ) external onlyOwner {
        require(
            Pair != pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(Pair, value);
    }

    function _setAutomatedMarketMakerPair(address Pair, bool value) private {
        automatedMarketMakerPairs[Pair] = value;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBot[from] && !_isBot[to]);

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
                        "Trading is not active."
                    );
                }

                // when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    // if their are a 0 block sniper blacklist them
                    if (block.timestamp == TradingActiveBlock) {
                        setBot(to, true);
                    }
                }
                // when sell
                if (!_isExcludedMaxTransactionAmount[from]) {
                    require(
                        amount <= maxTransactionAmount,
                        "transfer amount exceeds the maxTransactionAmount."
                    );
                }

                if (!_isExcludedMaxWalletAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
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
        uint256 reflectionFee = 0;

        if (takeFee) {
            // on buy
            if (automatedMarketMakerPairs[from] && to != address(router)) {
                fees = amount.mul(buyTotalFees).div(1000);
                getTokensForFees(
                    amount,
                    buyTreasuryFee,
                    buyBurnFee,
                    buyReflectionFee
                );
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && from != address(router)) {
                fees = amount.mul(sellTotalFees).div(1000);
                getTokensForFees(
                    amount,
                    sellTreasuryFee,
                    sellBurnFee,
                    sellReflectionFee
                );
            }

            if (fees > 0) {
                _tokenTransfer(from, address(this), fees, 0);

                if (tokensForBurn > 0) {
                    uint256 refiAmount = tokensForBurn + tokensForReflections;
                    bool refiAndBurn = refiAmount > 0;

                    if (refiAndBurn) {
                        burnAndReflect(refiAmount);
                    }
                }
                uint256 reflAmount = tokensForReflections;
                bool refi = reflAmount > 0;

                if (refi) {
                    Reflect(reflAmount);
                }
            }

            amount -= fees;
        }

        _tokenTransfer(from, to, amount, reflectionFee);
    }

    function getTokensForFees(
        uint256 _amount,
        uint256 _treasuryFee,
        uint256 _burnFee,
        uint256 _reflectionFee
    ) private {
        tokensForTreasury += _amount.mul(_treasuryFee).div(1000);
        tokensForBurn += _amount.mul(_burnFee).div(1000);
        tokensForReflections += _amount.mul(_reflectionFee).div(1000);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
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

        swapTokensForETH(contractBalance);

        tokensForTreasury = 0;
        (success, ) = payable(address(owner())).call{
            value: address(this).balance
        }("");
    }

    function totalSupply() public view override returns (uint256) {
        return _tSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function tokenFromReflection(
        uint256 rAmount
    ) private view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 reflectionFee
    ) private {
        _transferStandard(sender, recipient, amount, reflectionFee);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 reflectionFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount, reflectionFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(
        uint256 tAmount,
        uint256 reflectionFee
    ) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(
            tAmount,
            reflectionFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 reflectionFee
    ) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(reflectionFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    uint256 public BurnAndreflectReflectionFee = 50; //50
    uint256 public BurnAndreflectReflectionDivider = 2; // 2 i.e. burn half of the amount or 0% if relfect all

    function SetBurnAndReflectParams(
        uint256 _reflectdiv,
        uint256 _reflectfee
    ) public onlyOwner {
        BurnAndreflectReflectionDivider = _reflectdiv;
        BurnAndreflectReflectionFee = _reflectfee;
    }

    function burnAndReflect(uint256 _amount) private {
        _tokenTransfer(
            address(this),
            deadAddress,
            _amount,
            BurnAndreflectReflectionFee
        ); //was 50
        _tSupply -= _amount.div(BurnAndreflectReflectionDivider); //was 2
        tokensForReflections = 0;
        tokensForBurn = 0;
        updateLimits();
    }

    function Reflect(uint256 _amount) private {
        _tokenTransfer(address(this), deadAddress, _amount, 100);
        tokensForReflections = 0;
        updateLimits();
    }

    function burn(uint256 _amount) public {
        require(_amount > 0);
        address sender = msg.sender;
        _amount = _amount * (10 ** 18);
        _tokenTransfer(sender, deadAddress, _amount, 0);
        _tSupply -= _amount;
        updateLimits();
    }
}