// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswap.sol";

contract VogueToken is Context, ERC20, Ownable {
    using SafeMath for uint256;

    string private constant _NAME = "VOGUE Token";
    string private constant _SYMBOL = "VOGUE";
    uint8 private constant _DECIMALS = 18;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _tTotal = 10 * 10**9 * (10**_DECIMALS); // 10 Billion VogueToken
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint8 public liquidityFeeOnBuy = 2;
    uint8 public treasuryFeeOnBuy = 2;
    uint8 public VoguedistributionFeeOnBuy = 2;

    // Total of 6%

    uint8 public liquidityFeeOnSell = 4;
    uint8 public treasuryFeeOnSell = 1;
    uint8 public VoguedistributionFeeOnSell = 4;

    // Total of 9%

    uint256 public launchedAt;

    // State data for statistical purposes ONLY
    address public treasuryWallet;
    address private constant _DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    IUniswapV2Router02 public uniV2Router;
    address public uniV2Pair;

    uint256 public maxTxAmount = _tTotal.mul(1).div(10**2); // 1% of total supply
    uint256 public amountOfTokensToAddToLiquidityThreshold =
        maxTxAmount.mul(10).div(10**2); // 10% of max transaction amount

    bool public swapAndLiquifyEnabled = true;
    bool private _inSwap;
    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    event SwapAndLiquify(
        uint256 indexed ethReceived,
        uint256 indexed tokensIntoLiqudity
    );
    event UpdateUniSwapRouter(address indexed uniV2Router);
    event UpdateSwapAndLiquifyEnabled(bool indexed swapAndLiquifyEnabled);
    event ExcludeFromReflection(address indexed account);
    event IncludeInReflection(address indexed account);
    event SetIsExcludedFromFee(address indexed account, bool indexed flag);
    event ChangeFeesForNormalBuy(
        uint8 indexed liquidityFeeOnBuy,
        uint8 indexed treasuryFeeOnBuy,
        uint8 indexed VoguedistributionFeeOnBuy
    );
    event ChangeFeesForNormalSell(
        uint8 indexed liquidityFeeOnSell,
        uint8 indexed treasuryFeeOnSell,
        uint8 indexed VoguedistributionFeeOnSell
    );
    event UpdateTreasuryWallet(address indexed treasuryWallet);
    event UpdateAmountOfTokensToAddToLiquidityThreshold(
        uint256 indexed amountOfTokensToAddToLiquidityThreshold
    );
    event SetMaxTxPercent(uint256 indexed maxTxPercent);

    constructor(
        address _treasuryWalletAddress,
        address _uniswapV2Router02Address
    ) ERC20(_NAME, _SYMBOL) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _uniswapV2Router02Address
        );
        uniV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uniV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniV2Router)] = _MAX;
        treasuryWallet = _treasuryWalletAddress;
        _rOwned[msg.sender] = _rTotal;

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[treasuryWallet] = true;
        _excludeFromReflection(treasuryWallet);

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    receive() external payable {}

    fallback() external payable {}

    // Back-Up withdraw, in case ETH gets sent in here
    // NOTE: This function is to be called if and only if ETH gets sent into this contract.
    // On no other occurence should this function be called.
    function withdrawEthInWei(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        require(recipient != address(0), "Invalid Recipient!");
        require(amount > 0, "Invalid Amount!");
        // recipient.transfer(amount);
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Withdraw ERC20 tokens sent to this contract
    // NOTE: This function is to be called if and only if ERC20 tokens gets sent into this contract.
    // On no other occurence should this function be called.
    function withdrawTokens(address token, address recipient)
        external
        onlyOwner
    {
        require(token != address(0), "Invalid Token!");
        require(recipient != address(0), "Invalid Recipient!");

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            require(
                IERC20(token).transfer(recipient, balance),
                "Transfer Failed"
            );
        }
    }

    //  -----------------------------
    //  SETTERS (PROTECTED)
    //  -----------------------------
    function excludeFromReflection(address account) external onlyOwner {
        _excludeFromReflection(account);
        emit ExcludeFromReflection(account);
    }

    function includeInReflection(address account) external onlyOwner {
        _includeInReflection(account);
        emit IncludeInReflection(account);
    }

    function setIsExcludedFromFee(address account, bool flag)
        external
        onlyOwner
    {
        _setIsExcludedFromFee(account, flag);
        emit SetIsExcludedFromFee(account, flag);
    }

    function changeFeesForNormalBuy(
        uint8 _liquidityFeeOnBuy,
        uint8 _treasuryFeeOnBuy,
        uint8 _VoguedistributionFeeOnBuy
    ) external onlyOwner {
        require(_liquidityFeeOnBuy < 100, "Fee should be less than 100!");
        require(_treasuryFeeOnBuy < 100, "Fee should be less than 100!");
        require(
            _VoguedistributionFeeOnBuy < 100,
            "Fee should be less than 100!"
        );
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        treasuryFeeOnBuy = _treasuryFeeOnBuy;
        VoguedistributionFeeOnBuy = _VoguedistributionFeeOnBuy;
        emit ChangeFeesForNormalBuy(
            _liquidityFeeOnBuy,
            _treasuryFeeOnBuy,
            _VoguedistributionFeeOnBuy
        );
    }

    function changeFeesForNormalSell(
        uint8 _liquidityFeeOnSell,
        uint8 _treasuryFeeOnSell,
        uint8 _VoguedistributionFeeOnSell
    ) external onlyOwner {
        require(_liquidityFeeOnSell < 100, "Fee should be less than 100!");
        require(_treasuryFeeOnSell < 100, "Fee should be less than 100!");
        require(
            _VoguedistributionFeeOnSell < 100,
            "Fee should be less than 100!"
        );
        liquidityFeeOnSell = _liquidityFeeOnSell;
        treasuryFeeOnSell = _treasuryFeeOnSell;
        VoguedistributionFeeOnSell = _VoguedistributionFeeOnSell;
        emit ChangeFeesForNormalSell(
            _liquidityFeeOnSell,
            _treasuryFeeOnSell,
            _VoguedistributionFeeOnSell
        );
    }

    function updateTreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(_treasuryWallet != address(0), "Zero address not allowed!");
        _isExcludedFromFee[treasuryWallet] = false;
        treasuryWallet = _treasuryWallet;
        _isExcludedFromFee[treasuryWallet] = true;
        _excludeFromReflection(treasuryWallet);
        emit UpdateTreasuryWallet(_treasuryWallet);
    }

    function updateAmountOfTokensToAddToLiquidityThreshold(
        uint256 _amountOfTokensToAddToLiquidityThreshold
    ) external onlyOwner {
        amountOfTokensToAddToLiquidityThreshold =
            _amountOfTokensToAddToLiquidityThreshold *
            (10**_DECIMALS);
        emit UpdateAmountOfTokensToAddToLiquidityThreshold(
            _amountOfTokensToAddToLiquidityThreshold
        );
    }

    function updateUniSwapRouter(address _uniV2Router) external onlyOwner {
        require(_uniV2Router != address(0), "UniSwap Router Invalid!");
        require(
            address(uniV2Router) != _uniV2Router,
            "UniSwap Router already exists!"
        );
        _allowances[address(this)][address(uniV2Router)] = 0; // Set Allowance to 0
        uniV2Router = IUniswapV2Router02(_uniV2Router);
      
        _allowances[address(this)][address(uniV2Router)] = _MAX;
        emit UpdateUniSwapRouter(_uniV2Router);
    }

    function updateUniSwapPair(address _uniV2Pair) external onlyOwner {
        require(_uniV2Pair != address(0), "UniSwap Router Invalid!");
        require(
            uniV2Pair != _uniV2Pair,
            "UniSwap Pair already exists!"
        );
        uniV2Pair = _uniV2Pair;
    }



    function updateSwapAndLiquifyEnabled(bool _swapAndLiquifyEnabled)
        external
        onlyOwner
    {
        require(
            swapAndLiquifyEnabled != _swapAndLiquifyEnabled,
            "Value already exists!"
        );
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
        emit UpdateSwapAndLiquifyEnabled(_swapAndLiquifyEnabled);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit SetMaxTxPercent(maxTxPercent);
    }

    //  -----------------------------
    //  SETTERS
    //  -----------------------------

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    //  -----------------------------
    //  GETTERS
    //  -----------------------------
    function name() public pure override returns (string memory) {
        return _NAME;
    }

    function symbol() public pure override returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function isExcludedFromReflection(address account)
        public
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount)
        public
        view
        returns (uint256)
    {
        uint256 rAmount = tAmount.mul(_getRate());
        return rAmount;
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
        return rAmount.div(currentRate);
    }

    function getTotalCommunityReflection() external view returns (uint256) {
        return _tFeeTotal;
    }

    //  -----------------------------
    //  INTERNAL
    //  -----------------------------
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) {
            return (_rTotal, _tTotal);
        }

        return (rSupply, tSupply);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");

        if (sender != owner() && recipient != owner())
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maxTxAmount"
            );

        if (_inSwap) {
            _basicTransfer(sender, recipient, amount);
            return;
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            _basicTransfer(sender, recipient, amount);
        } else {
            if (recipient == uniV2Pair) {
                _normalSell(sender, recipient, amount);
            } else if (sender == uniV2Pair) {
                _normalBuy(sender, recipient, amount);
            } else {
                _basicTransfer(sender, recipient, amount);
            }
        }

        if (launchedAt == 0 && recipient == uniV2Pair) {
            launchedAt = block.number;
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 rAmount = reflectionFromToken(amount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient])
            _tOwned[recipient] = _tOwned[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _normalBuy(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rLiquidityFee = amount
            .mul(liquidityFeeOnBuy)
            .mul(currentRate)
            .div(100);
        uint256 rVoguedistributionFee = amount
            .mul(VoguedistributionFeeOnBuy)
            .mul(currentRate)
            .div(100);
        uint256 rTreasuryFee = amount
            .mul(treasuryFeeOnBuy)
            .mul(currentRate)
            .div(100);
        uint256 rTransferAmount = rAmount
            .sub(rLiquidityFee)
            .sub(rVoguedistributionFee)
            .sub(rTreasuryFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityFee);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient])
            _tOwned[recipient] = _tOwned[recipient].add(
                rTransferAmount.div(currentRate)
            );
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(
                rLiquidityFee.div(currentRate)
            );

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), (rLiquidityFee).div(currentRate));

        _sendToTreasuryWallet(
            sender,
            rTreasuryFee.div(currentRate),
            rTreasuryFee
        );
        _reflectFee(
            rVoguedistributionFee,
            rVoguedistributionFee.div(currentRate)
        );
    }

    function _normalSell(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rLiquidityFee = amount
            .mul(liquidityFeeOnSell)
            .mul(currentRate)
            .div(100);
        uint256 rVoguedistributionFee = amount
            .mul(VoguedistributionFeeOnSell)
            .mul(currentRate)
            .div(100);
        uint256 rTreasuryFee = amount
            .mul(treasuryFeeOnSell)
            .mul(currentRate)
            .div(100);
        uint256 rTransferAmount = rAmount
            .sub(rLiquidityFee)
            .sub(rVoguedistributionFee)
            .sub(rTreasuryFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityFee);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient])
            _tOwned[recipient] = _tOwned[recipient].add(
                rTransferAmount.div(currentRate)
            );
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(
                rLiquidityFee.div(currentRate)
            );

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), rLiquidityFee.div(currentRate));

        _sendToTreasuryWallet(
            sender,
            rTreasuryFee.div(currentRate),
            rTreasuryFee
        );
        _reflectFee(
            rVoguedistributionFee,
            rVoguedistributionFee.div(currentRate)
        );
    }

    function _sendToTreasuryWallet(
        address sender,
        uint256 tTreasuryFee,
        uint256 rTreasuryFee
    ) private {
        _rOwned[treasuryWallet] = _rOwned[treasuryWallet].add(rTreasuryFee);
        if (_isExcluded[treasuryWallet])
            _tOwned[treasuryWallet] = _tOwned[treasuryWallet].add(tTreasuryFee);
        emit Transfer(sender, treasuryWallet, tTreasuryFee);
    }


    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _excludeFromReflection(address account) private {
        // require(account !=  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude UniSwap router.');
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function _includeInReflection(address account) private {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = reflectionFromToken(_tOwned[account]);
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _setIsExcludedFromFee(address account, bool flag) private {
        _isExcludedFromFee[account] = flag;
    }
}