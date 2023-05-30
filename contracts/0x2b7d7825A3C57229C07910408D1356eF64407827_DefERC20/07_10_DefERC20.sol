// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract DefERC20 is Ownable, IERC20Metadata {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    mapping(address => bool) public isbotlisted;

    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal = 1_000_000_000_000 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Organic Inu";
    string private constant _symbol = "ORGANIC";
    uint8 private constant _decimals = 18;

    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet;

    uint256 public _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _marketingFee = 0;
    uint256 private _previousMarketingFee = _marketingFee;

    //Sale Fee
    uint256 public _saleTaxFee = 20; // 20%
    uint256 public _saleMarketingFee = 0;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public WETH;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public minimumTokensBeforeSwap = 100_000_000 * 10 ** 18;
    uint256 public _maxBuyTxAmount = 500_000 * 10 ** 18;
    uint256 public _maxSellTxAmount = 100_000 * 10 ** 18;
    uint256 public maxWalletToken = _tTotal;

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    event MaxWalletBalanceSet(uint256 balance);
    event MarketingWalletSet(address account);
    event BotListSet(address account, bool status);

    event SwapTokensForETH(uint256 amountIn, address[] path);
    event ErrorSwapTokensForETH(bytes err);
    event SwapETHForTokens(uint256 amountIn, address[] path);

    constructor(address _uniV2Router, address _marketingWallet) {
        marketingWallet = _marketingWallet;

        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniV2Router);

        WETH = _uniswapV2Router.WETH();

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), WETH);

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(
            tAmount
        );
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
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
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateTaxFee(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_taxFee).div(10 ** 2);
    }

    function removeAllFee() private {
        _taxFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingFee = _previousMarketingFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isbotlisted[from] && !isbotlisted[to], "botlisted address");

        bool excludedAccount = _isExcludedFromFee[from] || _isExcludedFromFee[to];

        if (uniswapV2Pair == from && !excludedAccount) {
            require(amount <= _maxBuyTxAmount, "Transfer amount exceeds the maxTxAmount.");

            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= maxWalletToken, "Exceeds maximum wallet token amount.");
        } else if (uniswapV2Pair == to && !excludedAccount) {
            require(amount <= _maxSellTxAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            if (balanceOf(from).sub(amount) == 0) {
                amount -= 10000;
                require(amount > 0, "Trying to make maximum sales.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            if (!inSwapAndLiquify && swapAndLiquifyEnabled && to == uniswapV2Pair && overMinimumTokenBalance) {
                contractTokenBalance = minimumTokensBeforeSwap;
                _swapTokensForWeth(contractTokenBalance);
            }
        }

        _tokenTransfer(from, to, amount);
    }

    function _swapTokensForWeth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        try
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                marketingWallet,
                block.timestamp
            )
        {
            emit SwapTokensForETH(tokenAmount, path);
        } catch (bytes memory error) {
            emit ErrorSwapTokensForETH(error);
        }
    }

    // this method is responsible for taking all fee where fee is require to be deducted.
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (recipient == uniswapV2Pair && !_isExcludedFromFee[sender]) {
            _setAllFees(_saleTaxFee, _saleMarketingFee);
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(
            tAmount
        );
        (tTransferAmount, rTransferAmount) = _takeMarketing(sender, tTransferAmount, rTransferAmount, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeMarketing(
        address sender,
        uint256 tTransferAmount,
        uint256 rTransferAmount,
        uint256 tAmount
    ) private returns (uint256, uint256) {
        if (_marketingFee == 0) {
            return (tTransferAmount, rTransferAmount);
        }
        uint256 tMarketing = tAmount.div(100).mul(_marketingFee);
        uint256 rMarketing = tMarketing.mul(_getRate());
        rTransferAmount = rTransferAmount.sub(rMarketing);
        tTransferAmount = tTransferAmount.sub(tMarketing);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
        emit Transfer(sender, address(this), tMarketing);
        return (tTransferAmount, rTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(
            tAmount
        );
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(
            tAmount
        );
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _setAllFees(uint256 taxFee, uint256 marketingFee) private {
        _taxFee = taxFee;
        _marketingFee = marketingFee;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function botlistAddress(address account, bool value) external onlyOwner {
        isbotlisted[account] = value;
        emit BotListSet(account, value);
    }

    function setMarketingWallet(address _newWallet) external onlyOwner {
        marketingWallet = _newWallet;
        emit MarketingWalletSet(_newWallet);
    }

    function setMaxWalletTokend(uint256 _maxToken) external onlyOwner {
        maxWalletToken = _maxToken * (10 ** 18);
        emit MaxWalletBalanceSet(maxWalletToken);
    }

    function setMinimumTokensBeforeSwap(uint256 newAmt) external onlyOwner {
        minimumTokensBeforeSwap = newAmt * (10 ** 18);
    }

    function setMaxBuyTxAmount(uint256 maxBuyTxAmount) external onlyOwner {
        require(maxBuyTxAmount > 0, "transaction amount must be greater than zero");
        _maxBuyTxAmount = maxBuyTxAmount * (10 ** 18);
    }

    function setMaxSellTxAmount(uint256 maxSellTxAmount) external onlyOwner {
        require(maxSellTxAmount > 0, "transaction amount must be greater than zero");
        _maxSellTxAmount = maxSellTxAmount * (10 ** 18);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setTaxFee(uint256 _value) external onlyOwner {
        _taxFee = _value;
    }

    function setMarketingFee(uint256 _value) external onlyOwner {
        _marketingFee = _value;
    }

    function setSaleTaxFee(uint256 _value) external onlyOwner {
        _saleTaxFee = _value;
    }

    function setSaleMarketingFee(uint256 _value) external onlyOwner {
        _saleMarketingFee = _value;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
}