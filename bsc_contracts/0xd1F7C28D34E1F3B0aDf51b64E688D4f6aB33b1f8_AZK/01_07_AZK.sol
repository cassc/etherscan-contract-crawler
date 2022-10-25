// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract AZK is IERC20, Ownable {
    uint8 private _decimals;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    string private _name;
    string private _symbol;

    uint256 private _rewardFee;
    uint256 private _previousRewardFee;

    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;

    uint256 private _lotteryFee;
    uint256 private _previousLotteryFee;

    uint256 private _burnFee;
    uint256 private _previousBurnFee;

    bool private inSwapAndLiquify;
    uint16 public sellRewardFee;
    uint16 public buyRewardFee;
    uint16 public sellLiquidityFee;
    uint16 public buyLiquidityFee;

    uint16 public sellLotteryFee;
    uint16 public buyLotteryFee;

    uint16 public sellBurnFee;
    uint16 public buyBurnFee;

    address public lotteryWallet;
    bool public isETHForLotteryFee;

    uint256 public minAmountToTakeFee;

    IUniswapV2Router02 public mainRouter;
    address public mainPair;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private _liquidityFeeTokens;
    uint256 private _lotteryFeeTokens;

    event UpdateLiquidityFee(uint16 sellLiquidityFee, uint16 buyLiquidityFee);
    event UpdateLotteryFee(uint16 sellLotteryFee, uint16 buyLotteryFee);
    event UpdateRewardFee(uint16 sellRewardFee, uint16 buyRewardFee);
    event UpdateLotteryWallet(address lotteryWallet, bool isETHForLotteryFee);

    event UpdateMinAmountToTakeFee(uint256 minAmountToTakeFee);
    event SetAutomatedMarketMakerPair(address pair, bool value);
    event ExcludedFromFee(address account, bool isEx);
    event SwapAndLiquify(uint256 tokensForLiquidity, uint256 ETHForLiquidity);
    event LotteryFeeTaken(
        uint256 lotteryFeeTokens,
        uint256 lotteryFeeETHSwapped
    );
    event UpdateMainRouter(address newAddress, address oldRouter);

    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address[2] memory _accounts,
        bool _isETHForLotteryFee,
        uint16[8] memory _fees
    ) {
        _decimals = __decimals;
        _name = __name;
        _symbol = __symbol;
        _tTotal = _totalSupply * (10**_decimals);
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_msgSender()] = _rTotal;
        require(_accounts[0] != address(0), "lottery wallet can not be 0");
        require(_accounts[1] != address(0), "Router address can not be 0");
        require(_fees[0] + _fees[2] + _fees[4] + _fees[6] <= 100);
        require(_fees[1] + _fees[3] + _fees[5] + _fees[7] <= 100);

        lotteryWallet = _accounts[0];
        mainRouter = IUniswapV2Router02(_accounts[1]);
        _approve(address(this), address(mainRouter), MAX);
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            mainRouter.WETH()
        );
        isETHForLotteryFee = _isETHForLotteryFee;
        sellLiquidityFee = _fees[0];
        buyLiquidityFee = _fees[1];
        sellLotteryFee = _fees[2];
        buyLotteryFee = _fees[3];
        sellRewardFee = _fees[4];
        buyRewardFee = _fees[5];
        sellBurnFee = _fees[6];
        buyBurnFee = _fees[7];

        minAmountToTakeFee = _tTotal / (10000);
        _isExcluded[address(0xdead)] = true;
        _excluded.push(address(0xdead));

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[lotteryWallet] = true;
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(0xdead)] = true;
        _setAutomatedMarketMakerPair(mainPair, true);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function updateMainRouter(address newAddress) public onlyOwner {
        require(
            newAddress != address(mainRouter),
            "The router already has that address"
        );
        emit UpdateMainRouter(newAddress, address(mainRouter));
        mainRouter = IUniswapV2Router02(newAddress);
        _approve(address(this), address(mainRouter), MAX);
        address _mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            mainRouter.WETH()
        );
        mainPair = _mainPair;
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tLottery,
            uint256 tBurn
        ) = _getValues(tAmount, currentRate);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity, tLottery, tBurn, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tLottery,
            uint256 tBurn
        ) = _getValues(tAmount, currentRate);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity, tLottery, tBurn, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tLottery,
            uint256 tBurn
        ) = _getValues(tAmount, currentRate);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity, tLottery, tBurn, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tLottery,
            uint256 tBurn
        ) = _getValues(tAmount, currentRate);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity, tLottery, tBurn, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - (rFee);
        _tFeeTotal = _tFeeTotal + (tFee);
    }

    function _getValues(uint256 tAmount, uint256 currentRate)
        private
        view
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tLottery,
            uint256 tBurn
        )
    {
        tFee = calculateRewardFee(tAmount);
        tLiquidity = calculateLiquidityFee(tAmount);
        tLottery = calculateLotteryFee(tAmount);
        tBurn = calculateBurnFee(tAmount);
        tTransferAmount = tAmount - tFee - tLiquidity - tLottery - tBurn;
        rAmount = tAmount * currentRate;
        rFee = tFee * currentRate;
        rTransferAmount =
            rAmount -
            rFee -
            tLiquidity *
            currentRate -
            tLottery *
            currentRate -
            tBurn *
            currentRate;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        if (_rewardFee == 0 && _liquidityFee == 0 && _lotteryFee == 0) return;

        _previousRewardFee = _rewardFee;
        _previousLiquidityFee = _liquidityFee;
        _previousLotteryFee = _lotteryFee;
        _previousBurnFee = _burnFee;

        _lotteryFee = 0;
        _rewardFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _liquidityFee = _previousLiquidityFee;
        _lotteryFee = _previousLotteryFee;
        _burnFee = _previousBurnFee;
    }

    function calculateRewardFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * (_rewardFee)) / (10**3);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * (_liquidityFee)) / (10**3);
    }

    function calculateLotteryFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * (_lotteryFee)) / (10**3);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return (_amount * (_burnFee)) / (10**3);
    }

    function _takeLiquidity(
        uint256 tLiquidity,
        uint256 tLottery,
        uint256 tBurn,
        uint256 currentRate
    ) private {
        _liquidityFeeTokens = _liquidityFeeTokens + tLiquidity;
        _lotteryFeeTokens = _lotteryFeeTokens + tLottery;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rLottery = tLottery * currentRate;
        _rOwned[address(0xdead)] =
            _rOwned[address(0xdead)] +
            tBurn *
            currentRate;
        _tOwned[address(0xdead)] = _tOwned[address(0xdead)] + tBurn;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity + rLottery;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] =
                _tOwned[address(this)] +
                tLiquidity +
                tLottery;
    }

    /////////////////////////////////////////////////////////////////////////////////
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - (subtractedValue)
        );
        return true;
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        uint256 currentRate = _getRate();
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , , ) = _getValues(tAmount, currentRate);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , , ) = _getValues(
                tAmount,
                currentRate
            );
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / (currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(
            _excluded.length + 1 <= 50,
            "Cannot exclude more than 50 accounts.  Include a previously excluded address."
        );
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                uint256 prev_rOwned = _rOwned[account];
                _rOwned[account] = _tOwned[account] * _getRate();
                _rTotal = _rTotal + _rOwned[account] - prev_rOwned;
                _isExcluded[account] = false;
                _excluded[i] = _excluded[_excluded.length - 1];
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function updateLiquidityFee(
        uint16 _sellLiquidityFee,
        uint16 _buyLiquidityFee
    ) external onlyOwner {
        require(
            _sellLiquidityFee + sellLotteryFee + sellRewardFee + sellBurnFee <=
                100,
            "sell fee <= 10%"
        );
        require(
            _buyLiquidityFee + buyLotteryFee + buyRewardFee + buyBurnFee <= 100,
            "buy fee <= 10%"
        );

        sellLiquidityFee = _sellLiquidityFee;
        buyLiquidityFee = _buyLiquidityFee;
        emit UpdateLiquidityFee(sellLiquidityFee, buyLiquidityFee);
    }

    function updateLotteryFee(uint16 _sellLotteryFee, uint16 _buyLotteryFee)
        external
        onlyOwner
    {
        require(
            _sellLotteryFee + sellLiquidityFee + sellRewardFee + sellBurnFee <=
                100,
            "sell fee <= 10%"
        );
        require(
            _buyLotteryFee + buyLiquidityFee + buyRewardFee + buyBurnFee <= 100,
            "buy fee <= 10%"
        );
        sellLotteryFee = _sellLotteryFee;
        buyLotteryFee = _buyLotteryFee;
        emit UpdateLotteryFee(sellLotteryFee, buyLotteryFee);
    }

    function updateRewardFee(uint16 _sellRewardFee, uint16 _buyRewardFee)
        external
        onlyOwner
    {
        require(
            _sellRewardFee + sellLiquidityFee + sellLotteryFee + sellBurnFee <=
                100,
            "sell fee <= 10%"
        );
        require(
            _buyRewardFee + buyLiquidityFee + buyLotteryFee + buyBurnFee <= 100,
            "buy fee <= 10%"
        );
        sellRewardFee = _sellRewardFee;
        buyRewardFee = _buyRewardFee;
        emit UpdateRewardFee(sellRewardFee, buyRewardFee);
    }

    function updateBurnFee(uint16 _sellBurnFee, uint16 _buyBurnFee)
        external
        onlyOwner
    {
        require(
            sellRewardFee + sellLiquidityFee + sellLotteryFee + _sellBurnFee <=
                100,
            "sell fee <= 10%"
        );
        require(
            buyRewardFee + buyLiquidityFee + buyLotteryFee + _buyBurnFee <= 100,
            "buy fee <= 10%"
        );
        sellBurnFee = _sellBurnFee;
        buyBurnFee = _buyBurnFee;
        emit UpdateRewardFee(sellBurnFee, buyBurnFee);
    }

    function updateLotteryWallet(
        address _lotteryWallet,
        bool _isETHForLotteryFee
    ) external onlyOwner {
        require(_lotteryWallet != address(0), "lottery wallet can't be 0");
        lotteryWallet = _lotteryWallet;
        isETHForLotteryFee = _isETHForLotteryFee;
        isExcludedFromFee[_lotteryWallet] = true;
        emit UpdateLotteryWallet(lotteryWallet, _isETHForLotteryFee);
    }

    function updateMinAmountToTakeFee(uint256 _minAmountToTakeFee)
        external
        onlyOwner
    {
        require(_minAmountToTakeFee > 0, ">0");
        minAmountToTakeFee = _minAmountToTakeFee * (10**_decimals);
        emit UpdateMinAmountToTakeFee(minAmountToTakeFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        if (value) excludeFromReward(pair);
        else includeInReward(pair);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFee(address account, bool isEx) external onlyOwner {
        isExcludedFromFee[account] = isEx;
        emit ExcludedFromFee(account, isEx);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minAmountToTakeFee;

        // Take Fee
        if (
            !inSwapAndLiquify &&
            overMinimumTokenBalance &&
            balanceOf(mainPair) > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            takeFee();
        }
        removeAllFee();

        // If any account belongs to isExcludedFromFee account then remove the fee
        if (
            !inSwapAndLiquify &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _rewardFee = buyRewardFee;
                _liquidityFee = buyLiquidityFee;
                _lotteryFee = buyLotteryFee;
                _burnFee = buyBurnFee;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _rewardFee = sellRewardFee;
                _liquidityFee = sellLiquidityFee;
                _lotteryFee = sellLotteryFee;
                _burnFee = sellBurnFee;
            }
        }
        _tokenTransfer(from, to, amount);
        restoreAllFee();
    }

    function takeFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensTaken = _liquidityFeeTokens + (_lotteryFeeTokens);
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityFeeTokens / 2;
        uint256 initialETHBalance = address(this).balance;
        uint256 ETHForLiquidity;
        if (isETHForLotteryFee) {
            uint256 tokenForSwap = tokensForLiquidity + _lotteryFeeTokens;
            if (tokenForSwap > 0) swapTokensForETH(tokenForSwap);
            uint256 ETHBalance = address(this).balance - initialETHBalance;
            uint256 ETHForLottery = (ETHBalance * _lotteryFeeTokens) /
                tokenForSwap;
            ETHForLiquidity = ETHBalance - ETHForLottery;
            if (ETHForLottery > 0) {
                (bool success, ) = address(lotteryWallet).call{
                    value: ETHForLottery
                }("");
                if (success) _lotteryFeeTokens = 0;

                emit LotteryFeeTaken(0, ETHForLottery);
            }
        } else {
            if (tokensForLiquidity > 0) swapTokensForETH(tokensForLiquidity);
            ETHForLiquidity = address(this).balance - initialETHBalance;
            if (_lotteryFeeTokens > 0) {
                _transfer(address(this), lotteryWallet, _lotteryFeeTokens);
                emit LotteryFeeTaken(_lotteryFeeTokens, 0);
                _lotteryFeeTokens = 0;
            }
        }

        if (tokensForLiquidity > 0 && ETHForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, ETHForLiquidity);
            emit SwapAndLiquify(tokensForLiquidity, ETHForLiquidity);
        }

        _liquidityFeeTokens = 0;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = mainRouter.WETH();
        mainRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        mainRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    receive() external payable {}
}