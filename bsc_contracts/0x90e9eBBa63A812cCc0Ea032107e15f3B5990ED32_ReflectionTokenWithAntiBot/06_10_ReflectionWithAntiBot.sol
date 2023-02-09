// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapCaller.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IGemAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract ReflectionTokenWithAntiBot is IERC20Upgradeable, OwnableUpgradeable {
    IUniswapCaller public constant uniswapCaller =
        IUniswapCaller(0x1CA3AebD320C0d802F57B707608D6927118bfeF9);
    address public baseTokenForPair;
    uint8 private _decimals;
    address public gemAntiBot;
    bool public antiBotEnabled;
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

    uint256 private _marketingFee;
    uint256 private _previousMarketingFee;
    bool private inSwapAndLiquify;
    uint16 public sellRewardFee;
    uint16 public buyRewardFee;
    uint16 public sellLiquidityFee;
    uint16 public buyLiquidityFee;

    uint16 public sellMarketingFee;
    uint16 public buyMarketingFee;

    address public marketingWallet;
    bool public isMarketingFeeBaseToken;


    uint256 public minAmountToTakeFee;
    uint256 public maxWallet;
    uint256 public maxTransactionAmount;


    IUniswapV2Router02 public mainRouter;
    address public mainPair;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private _liquidityFeeTokens;
    uint256 private _marketingFeeTokens;

    event UpdateLiquidityFee(
        uint16 newSellLiquidityFee,
        uint16 newBuyLiquidityFee,
        uint16 oldSellLiquidityFee,
        uint16 oldBuyLiquidityFee
    );
    event UpdateMarketingFee(
        uint16 newSellMarketingFee,
        uint16 newBuyMarketingFee,
        uint16 oldSellMarketingFee,
        uint16 oldBuyMarketingFee
    );
    event UpdateRewardFee(
        uint16 newSellRewardFee,
        uint16 newBuyRewardFee,
        uint16 oldSellRewardFee,
        uint16 oldBuyRewardFee
    );  
    event UpdateMarketingWallet(
        address indexed newMarketingWallet,
        bool newIsMarketingFeeBaseToken,
        address indexed oldMarketingWallet,
        bool oldIsMarketingFeeBaseToken
    );

    event UpdateMinAmountToTakeFee(uint256 newMinAmountToTakeFee, uint256 oldMinAmountToTakeFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);
    event ExcludedFromFee(address indexed account, bool isEx);
    event SwapAndLiquify(uint256 tokensForLiquidity, uint256 baseTokenForLiquidity);
    event MarketingFeeTaken(
        uint256 marketingFeeTokens,
        uint256 marketingFeeBaseTokenSwapped
    );
    event ExcludedFromMaxTransactionAmount(address indexed account, bool isExcluded);
    event UpdateUniswapRouter(address indexed newAddress, address indexed oldRouter);
    event UpdateMaxWallet(uint256 newMaxWallet, uint256 oldMaxWallet);
    event UpdateMaxTransactionAmount(uint256 newMaxTransactionAmount, uint256 oldMaxTransactionAmount);
    function initialize(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees,
        address _gemAntiBot
    ) initializer payable public {
        require(msg.value >= 0.1 ether, "not enough fee");
        (bool sent, ) = payable(0x8e89BeEba31C5521601449410215De43D23f4b45).call{value: msg.value}("");
        require(sent, "fail to transfer fee");
        baseTokenForPair=_accounts[2];
        _decimals = __decimals;
        _name = __name;
        _symbol = __symbol;
        _tTotal = _totalSupply ;
        _transferOwnership(tx.origin);
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[owner()] = _rTotal;
        require(_accounts[0] != address(0), "marketing wallet can not be 0");
        require(_accounts[1] != address(0), "Router address can not be 0");
        require(_fees[0]+(_fees[2])+(_fees[4]) <= 200, "sell fee <= 20%");
        require(_fees[1]+(_fees[3])+(_fees[5]) <= 200, "buy fee <= 20%");
        
        marketingWallet = _accounts[0];
        isMarketingFeeBaseToken = _isMarketingFeeBaseToken;
        emit UpdateMarketingWallet(
            marketingWallet,
            isMarketingFeeBaseToken,
            address(0),
            false
        );
        mainRouter = IUniswapV2Router02(_accounts[1]);
        emit UpdateUniswapRouter(address(mainRouter), address(0));
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        
        sellLiquidityFee = _fees[0];
        buyLiquidityFee = _fees[1];
        emit UpdateLiquidityFee(
            sellLiquidityFee,
            buyLiquidityFee,
            0,
            0
        );
        sellMarketingFee = _fees[2];
        buyMarketingFee = _fees[3];
        emit UpdateMarketingFee(
            sellMarketingFee,
            buyMarketingFee,
            0,
            0
        );
        sellRewardFee = _fees[4];
        buyRewardFee = _fees[5];
        emit UpdateRewardFee(
            sellRewardFee,
            buyRewardFee,
            0,
            0
        );
        minAmountToTakeFee = _totalSupply/(10000);
        emit UpdateMinAmountToTakeFee(minAmountToTakeFee, 0);
        require(_maxTransactionAmount>0, "maxTransactionAmount > 0");
        require(_maxWallet>0, "maxWallet > 0");
        maxWallet=_maxWallet;
        emit UpdateMaxWallet(maxWallet, 0);
        maxTransactionAmount=_maxTransactionAmount;
        emit UpdateMaxTransactionAmount(maxTransactionAmount, 0);
        _isExcluded[address(0xdead)] = true;
        _excluded.push(address(0xdead));

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(0xdead)] = true;
        isExcludedFromMaxTransactionAmount[address(0xdead)]=true;
        isExcludedFromMaxTransactionAmount[address(this)]=true;
        isExcludedFromMaxTransactionAmount[marketingWallet]=true;
        isExcludedFromMaxTransactionAmount[owner()]=true;
        _setAutomatedMarketMakerPair(mainPair, true);
        emit Transfer(address(0), owner(), _totalSupply);
        gemAntiBot = _gemAntiBot;
        IGemAntiBot(gemAntiBot).setTokenOwner(owner());
        antiBotEnabled = true;
    }

    function setUsingAntiBot(bool enabled_) external onlyOwner {
        antiBotEnabled = enabled_;
    }

    function updateUniswapPair(address _baseTokenForPair) external onlyOwner
    {
        require(
            _baseTokenForPair != baseTokenForPair,
            "The baseTokenForPair already has that address"
        );
        baseTokenForPair=_baseTokenForPair;
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    function updateUniswapRouter(address newAddress) public onlyOwner {
        require(
            newAddress != address(mainRouter),
            "The router already has that address"
        );
        emit UpdateUniswapRouter(newAddress, address(mainRouter));
        mainRouter = IUniswapV2Router02(newAddress);
        address _mainPair = IUniswapV2Factory(mainRouter.factory())
            .createPair(address(this), baseTokenForPair);
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
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeLiquidity(tLiquidity, tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeLiquidity(tLiquidity, tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeLiquidity(tLiquidity, tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeLiquidity(tLiquidity, tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet>0, "maxWallet > 0");
        emit UpdateMaxWallet(_maxWallet, maxWallet);
        maxWallet = _maxWallet;
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount)
        external
        onlyOwner
    {
        require(_maxTransactionAmount>0, "maxTransactionAmount > 0");
        emit UpdateMaxTransactionAmount(_maxTransactionAmount, maxTransactionAmount);
        maxTransactionAmount = _maxTransactionAmount;
    }   
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal-(rFee);
        _tFeeTotal = _tFeeTotal+(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tMarketing,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity,
            tMarketing
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateRewardFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount-(tFee)-(tLiquidity)-(
            tMarketing
        );
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tMarketing,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount*(currentRate);
        uint256 rFee = tFee*(currentRate);
        uint256 rLiquidity = tLiquidity*(currentRate);
        uint256 rMarketing = tMarketing*(currentRate);
        uint256 rTransferAmount = rAmount-(rFee)-(rLiquidity)-(
            rMarketing
        );
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply-(_rOwned[_excluded[i]]);
            tSupply = tSupply-(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal/(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        if (_rewardFee == 0 && _liquidityFee == 0 && _marketingFee == 0) return;

        _previousRewardFee = _rewardFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;

        _marketingFee = 0;
        _rewardFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }

    function calculateRewardFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_rewardFee)/(10**3);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_liquidityFee)/(10**3);
    }

    function calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_marketingFee)/(10**3);
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 tMarketing) private {
        _liquidityFeeTokens = _liquidityFeeTokens+(tLiquidity);
        _marketingFeeTokens = _marketingFeeTokens+(tMarketing);
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity*(currentRate);
        uint256 rMarketing = tMarketing*(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)]+(rLiquidity)+(
            rMarketing
        );
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)]+(tLiquidity)+(
                tMarketing
            );
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
            _allowances[sender][_msgSender()]-amount
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
            _allowances[_msgSender()][spender]+(addedValue)
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
            _allowances[_msgSender()][spender]-(
                subtractedValue
            )
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
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
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
        return rAmount/(currentRate);
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
                uint256 prev_rOwned=_rOwned[account];
                _rOwned[account]=_tOwned[account]*_getRate();
                _rTotal=_rTotal+_rOwned[account]-prev_rOwned;
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
            _sellLiquidityFee+(sellMarketingFee)+(sellRewardFee) <= 200,
            "sell fee <= 20%"
        );
        require(
            _buyLiquidityFee+(buyMarketingFee)+(buyRewardFee) <= 200,
            "buy fee <= 20%"
        );
        emit UpdateLiquidityFee(
            _sellLiquidityFee,
            _buyLiquidityFee,
            sellLiquidityFee,
            buyLiquidityFee
        );
        sellLiquidityFee = _sellLiquidityFee;
        buyLiquidityFee = _buyLiquidityFee;        
    }

    function updateMarketingFee(
        uint16 _sellMarketingFee,
        uint16 _buyMarketingFee
    ) external onlyOwner {
        require(
            _sellMarketingFee+(sellLiquidityFee)+(sellRewardFee) <= 200,
            "sell fee <= 20%"
        );
        require(
            _buyMarketingFee+(buyLiquidityFee)+(buyRewardFee) <= 200,
            "buy fee <= 20%"
        );
        emit UpdateMarketingFee(
            _sellMarketingFee,
            _buyMarketingFee,
            sellMarketingFee,
            buyMarketingFee
        );
        sellMarketingFee = _sellMarketingFee;
        buyMarketingFee = _buyMarketingFee;        
    }

    function updateRewardFee(
        uint16 _sellRewardFee,
        uint16 _buyRewardFee
    ) external onlyOwner {
        require(
            _sellRewardFee+(sellLiquidityFee)+(sellMarketingFee) <= 200,
            "sell fee <= 20%"
        );
        require(
            _buyRewardFee+(buyLiquidityFee)+(buyMarketingFee) <= 200,
            "buy fee <= 20%"
        );
        emit UpdateRewardFee(
            _sellRewardFee, 
            _buyRewardFee,
            sellRewardFee, 
            buyRewardFee
        );
        sellRewardFee = _sellRewardFee;
        buyRewardFee = _buyRewardFee;        
    }

    function updateMarketingWallet(
        address _marketingWallet,
        bool _isMarketingFeeBaseToken
    ) external onlyOwner {
        require(_marketingWallet != address(0), "marketing wallet can't be 0");
        emit UpdateMarketingWallet(_marketingWallet, _isMarketingFeeBaseToken,
            marketingWallet, isMarketingFeeBaseToken);
        marketingWallet = _marketingWallet;
        isMarketingFeeBaseToken = _isMarketingFeeBaseToken;
        isExcludedFromFee[_marketingWallet] = true;        
    }

    function updateMinAmountToTakeFee(uint256 _minAmountToTakeFee)
        external
        onlyOwner
    {
        require(_minAmountToTakeFee > 0, "minAmountToTakeFee > 0");
        emit UpdateMinAmountToTakeFee(_minAmountToTakeFee, minAmountToTakeFee);
        minAmountToTakeFee = _minAmountToTakeFee;        
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) excludeFromReward(pair);
        else includeInReward(pair);
        isExcludedFromMaxTransactionAmount[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function excludeFromFee(address account, bool isEx) external onlyOwner {
        require(isExcludedFromFee[account] != isEx, "already");
        isExcludedFromFee[account] = isEx;
        emit ExcludedFromFee(account, isEx);
    }

    function excludeFromMaxTransactionAmount(address account, bool isEx)
        external
        onlyOwner
    {
        require(isExcludedFromMaxTransactionAmount[account]!=isEx, "already");
        isExcludedFromMaxTransactionAmount[account] = isEx;
        emit ExcludedFromMaxTransactionAmount(account, isEx);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        if (antiBotEnabled) {
            IGemAntiBot(gemAntiBot).onPreTransferCheck(from, to, amount);
        }
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
                _marketingFee = buyMarketingFee;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _rewardFee = sellRewardFee;
                _liquidityFee = sellLiquidityFee;
                _marketingFee = sellMarketingFee;
            }
        }
        _tokenTransfer(from, to, amount);
        restoreAllFee();
        if (!inSwapAndLiquify) {
            if (!isExcludedFromMaxTransactionAmount[from]) {
                require(
                    amount < maxTransactionAmount,
                    "ERC20: exceeds transfer limit"
                );
            }
            if (!isExcludedFromMaxTransactionAmount[to]) {
                require(
                    balanceOf(to) < maxWallet,
                    "ERC20: exceeds max wallet limit"
                );
            }
        }
    }

    function takeFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensTaken = _liquidityFeeTokens+(_marketingFeeTokens);
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityFeeTokens / 2;
        uint256 initialBaseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance
            : IERC20Upgradeable(baseTokenForPair).balanceOf(address(this));
        uint256 baseTokenForLiquidity;
        if (isMarketingFeeBaseToken) {
            uint256 tokensForSwap=tokensForLiquidity+_marketingFeeTokens;
            if(tokensForSwap>0)
                swapTokensForBaseToken(tokensForSwap);
            uint256 baseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance-initialBaseTokenBalance
                : IERC20Upgradeable(baseTokenForPair).balanceOf(address(this))-initialBaseTokenBalance;
            uint256 baseTokenForMarketing = baseTokenBalance*(_marketingFeeTokens)/tokensForSwap;
            baseTokenForLiquidity = baseTokenBalance - baseTokenForMarketing;
            if(baseTokenForMarketing>0){
                if(baseTokenForPair==mainRouter.WETH()){
                    (bool success, )=address(marketingWallet).call{value: baseTokenForMarketing}("");
                    if(success){
                        _marketingFeeTokens = 0;
                        emit MarketingFeeTaken(0, baseTokenForMarketing);
                    }
                }else{
                    IERC20Upgradeable(baseTokenForPair).transfer(marketingWallet, baseTokenForMarketing);
                    _marketingFeeTokens = 0;
                    emit MarketingFeeTaken(0, baseTokenForMarketing);
                }       
            }            
        } else {
            if(tokensForLiquidity>0)
                swapTokensForBaseToken(tokensForLiquidity);
            baseTokenForLiquidity = baseTokenForPair==mainRouter.WETH() ? address(this).balance-initialBaseTokenBalance
                : IERC20Upgradeable(baseTokenForPair).balanceOf(address(this))-initialBaseTokenBalance;
            if(_marketingFeeTokens>0){
                _transfer(address(this), marketingWallet, _marketingFeeTokens);
                emit MarketingFeeTaken(_marketingFeeTokens, 0);
                _marketingFeeTokens = 0;
            }            
        }

        if (tokensForLiquidity > 0 && baseTokenForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, baseTokenForLiquidity);
            emit SwapAndLiquify(tokensForLiquidity, baseTokenForLiquidity);
        }

        _liquidityFeeTokens = 0;
        
    }
    
    function swapTokensForBaseToken(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = baseTokenForPair;
        if (path[1] == mainRouter.WETH()){
            _approve(address(this), address(mainRouter), tokenAmount);
            mainRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of BaseToken
                path,
                address(this),
                block.timestamp
            );
        }else{
            _approve(address(this), address(uniswapCaller), tokenAmount);
            uniswapCaller.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    address(mainRouter),
                    tokenAmount,
                    0, // accept any amount of BaseToken
                    path,
                    block.timestamp
                );
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 baseTokenAmount) private {        
        _approve(address(this), address(mainRouter), tokenAmount);
        IERC20Upgradeable(baseTokenForPair).approve(address(mainRouter), baseTokenAmount);
        if (baseTokenForPair == mainRouter.WETH()) 
            mainRouter.addLiquidityETH{value: baseTokenAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(0xdead),
                block.timestamp
            );
        else
            mainRouter.addLiquidity(
                address(this),
                baseTokenForPair,
                tokenAmount,
                baseTokenAmount,
                0,
                0,
                address(0xdead),
                block.timestamp
            );
    }
    receive() external payable {}
}