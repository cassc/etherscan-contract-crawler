// Mellivora Finance: Redefining Decentralized Finance through Frictionless Yield Protocol (FYP)

// Website: https://mellivora.finance/
// Docs: https://docs.mellivora.finance/
// Twitter: https://twitter.com/MellivoraERC
// Telegram: https://t.me/MellivoraERC

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity 0.8.21;

interface IPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
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

interface IUniswapRouter {
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

abstract contract TokenBase is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory _tokenName, string memory _tokenSymbol) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = 9;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Mellivora is TokenBase, Ownable {
    address payable public treasuryAddress;
    address public immutable deadAddress = address(0xDEAD);
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public maxAmount = (_tTotal * 2) / 100; // 2%
    uint256 public maxWallet = (_tTotal * 2) / 100; // 2%

    uint256 private minimumTokensBeforeSwap = _tTotal / 200; // 0.5%

    bool public limitsInEffect = true;
    bool public tradingEnable = false;
    uint256 public latestRocketLaunch;
    uint256 public rocketLaunchCooldown = 2 hours;
    uint256 public launchETHPercent = 5;
    uint256 public launchCount;
    uint256 public totalETHLaunched;

    uint256 private _initTax = 30;
    uint256 private _reduceTaxAt = 30;
    Taxes public _tax = Taxes(2, 2, 2);

    uint256 private _buyCount = 0;
    uint256 private _sellCount = 0;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    struct Taxes {
        uint256 treasury;
        uint256 rewards;
        uint256 launchRocket;
    }

    IUniswapRouter public immutable router;
    address public immutable pair;

    bool inSwap;

    event Distribute(uint256 amount);
    event SwapEnabled();
    event OffLimits();
    event LaunchETH(uint256 amount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _treasuryAddress) TokenBase("Mellivora", "MLVR") {
        treasuryAddress = payable(_treasuryAddress);
        _rOwned[_msgSender()] = _rTotal;
        router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(router)] = true;
        _isExcludedFromFee[deadAddress] = true;

        excludeFromReward(address(this));
        excludeFromReward(deadAddress);
        excludeFromReward(pair);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        require(
            _allowances[_msgSender()][spender] >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(
        uint256 tAmount
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (uint256 rAmount, , , ) = _getValues(tAmount, 0);
        return rAmount;
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , ) = _getValues(tAmount, 0);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rTotal = _rTotal - (rAmount);
        _tFeeTotal = _tFeeTotal + (tAmount);
    }

    function enableSwap() external onlyOwner {
        tradingEnable = true;
        emit SwapEnabled();
    }

    function offLimits() external onlyOwner {
        limitsInEffect = false;
        emit OffLimits();
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(
            _treasuryAddress != address(0),
            "Cannot set treasury to zero address"
        );
        treasuryAddress = payable(_treasuryAddress);
    }

    function setLaunchRocketETHPercent(uint256 _launchETHPercent) external onlyOwner {
        require(
            _launchETHPercent < 10 && _launchETHPercent > 1,
            "Invalid percentage"
        );
        launchETHPercent = _launchETHPercent;
    }

    function launchRocket() external {
        require(
            latestRocketLaunch + rocketLaunchCooldown < block.timestamp,
            "Rocket launch cooldown in effect"
        );
        latestRocketLaunch = block.timestamp;
        uint256 amountETH = address(this).balance;
        uint256 amountLimit = IERC20(router.WETH()).balanceOf(pair);

        if (amountETH > (amountLimit * launchETHPercent) / 100) {
            amountETH = (amountLimit * launchETHPercent) / 100;
        }

        launchRocketAndBurn(amountETH);
        totalETHLaunched += amountETH;
        launchCount++;
        emit LaunchETH(amountETH);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function calculateTaxFee(
        uint256 _amount,
        address sender,
        address recipient
    ) private view returns (uint256) {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            return 0;
        }
        if (sender != pair && recipient != pair) {
            return 0;
        }
        if (sender == pair && _buyCount < _reduceTaxAt) {
            return (_amount * _initTax) / 100;
        }
        if (recipient == pair && _sellCount < _reduceTaxAt) {
            return (_amount * _initTax) / 100;
        }
        uint256 _totalTax = _tax.treasury + _tax.rewards + _tax.launchRocket;
        return (_amount * _totalTax) / 100;
    }

    function setMinimumTokensBeforeSwap(
        uint256 _minimumTokensBeforeSwap
    ) external onlyOwner {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!inSwap && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingEnable, "Trading not live");
            if (limitsInEffect) {
                if (from == pair || to == pair) {
                    require(amount <= maxAmount, "Max Tx Exceeded");
                }
                if (to != pair) {
                    require(
                        balanceOf(to) + amount <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
            }

            if (to == pair) {
                _buyCount++;
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= minimumTokensBeforeSwap) {
                    swapTokens(minimumTokensBeforeSwap);
                }
            }
            if (from == pair) {
                _sellCount++;
            }
        }
        _tokenTransfer(from, to, amount);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 transferredBalance = address(this).balance - initialBalance;
        uint256 _totalTax = _tax.treasury + _tax.rewards + _tax.launchRocket;
        transferToAddressETH(
            treasuryAddress,
            (transferredBalance / _totalTax) * _tax.treasury
        );
    }

    function launchRocketAndBurn(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapETHForTokens(amount);
        }
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
        uint256 tFee = calculateTaxFee(tAmount, sender, recipient);
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount
        ) = _getValues(tAmount, tFee);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFee(rFee, tFee, sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 tFee = calculateTaxFee(tAmount, sender, recipient);
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount
        ) = _getValues(tAmount, tFee);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFee(rFee, tFee, sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 tFee = calculateTaxFee(tAmount, sender, recipient);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount
        ) = _getValues(tAmount, tFee);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFee(rFee, tFee, sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 tFee = calculateTaxFee(tAmount, sender, recipient);
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount
        ) = _getValues(tAmount, tFee);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFee(rFee, tFee, sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFee(
        uint256 rFeeTotal,
        uint256 tFeeTotal,
        address _from
    ) private {
        uint256 _totalTax = _tax.treasury + _tax.rewards + _tax.launchRocket;
        uint256 rFeeReflect = (rFeeTotal * (_tax.rewards)) / (_totalTax);
        uint256 tFeeReflect = (tFeeTotal * (_tax.rewards)) / (_totalTax);

        // reflect fees
        _rTotal = _rTotal - (rFeeReflect);
        _tFeeTotal = _tFeeTotal + (tFeeReflect);

        // treasury + launchRocket fees
        _rOwned[address(this)] =
            _rOwned[address(this)] +
            (rFeeTotal - rFeeReflect);

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] =
                _tOwned[address(this)] +
                (tFeeTotal - tFeeReflect);
        }
        emit Transfer(_from, address(this), tFeeTotal - tFeeReflect);
        emit Distribute(tFeeReflect);
    }

    function _getValues(
        uint256 tAmount,
        uint256 tFee
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tTransferAmount = _getTValues(tAmount, tFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            _getRate()
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 tFee
    ) private pure returns (uint256) {
        uint256 tTransferAmount = tAmount - (tFee);
        return tTransferAmount;
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee * (currentRate);
        uint256 rTransferAmount = rAmount - (rFee);
        return (rAmount, rTransferAmount, rFee);
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

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function transferToAddressETH(
        address payable recipient,
        uint256 amount
    ) private {
        recipient.transfer(amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), _tTotal / 200);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp
        );
    }

    receive() external payable {}
}