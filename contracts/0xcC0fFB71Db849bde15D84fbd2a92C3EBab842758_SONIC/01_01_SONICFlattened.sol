/*
  Website: https://sonic.markets

  Telegram: https://t.me/sonicportal

       ___------__
 |\__-- /\       _-
 |/    __      -
 //\  /  \    /__
 |  o|  0|__     --_
 \\____-- __ \   ___-
 (@@    __/  / /_
    -_____---   --_
     //  \ \\   ___-
   //|\__/  \\  \
   \_-\_____/  \-\
        // \\--\|   <== The dev made this ASCII art all by himself! 🤭
   ____//  ||_
  /_____\ /___\
______________________
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

contract SONIC is IERC20, Ownable {
    string public constant _name = "Sonic The Hedgehog";
    string public constant _symbol = "SONIC";
    uint8 public constant _decimals = 9;

    uint256 public constant _totalSupply = 100_000_000_000_000 * (10 ** _decimals);

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    mapping (address => bool) public noTax;
    mapping (address => bool) public noMax;
    mapping (address => bool) public dexPair;

    mapping (address => bool) public blacklist;

    uint256 public buyFeeTeam = 0;
    uint256 public buyFeeLiqToken = 0;
    uint256 public buyFee = 0;
    uint256 public sellFeeTeam = 0;
    uint256 public sellFeeLiqToken = 0;
    uint256 public sellFee = 0;

    uint256 private _tokensTeam = 0;
    uint256 private _tokensLiqToken = 0;

    address public walletTeam = msg.sender;
    address public walletLiqToken = msg.sender;

    address public immutable WETH;
    IUniswapV2Router02 public immutable router;
    address public pair;

    uint256 public maxWallet = 2_500_000_000_000 * (10 ** _decimals);

    bool private _swapping;

    modifier swapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;

        noTax[msg.sender] = true;
        noMax[msg.sender] = true;

        dexPair[pair] = true;
        noMax[pair] = true;

        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        require(!blacklist[sender] && !blacklist[recipient], "Blacklisted");
        if (_swapping) return _basicTransfer(sender, recipient, amount);

        address routerAddress = address(router);
        bool _sell = dexPair[recipient] || recipient == routerAddress;

        if (!_sell && !noMax[recipient]) require((_balances[recipient] + amount) < maxWallet, "Max wallet triggered");

        if (_sell) {
            if (!dexPair[msg.sender] && !_swapping && _balances[address(this)] >= 1_000_000_000) _sellTaxedTokens();
        }

        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = (((dexPair[sender] || sender == address(router)) || (dexPair[recipient]|| recipient == address(router))) ? !noTax[sender] && !noTax[recipient] : false) ? _collectTaxedTokens(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        return true;
    }

    function _collectTaxedTokens(address sender, address receiver, uint256 amount) private returns (uint256) {
        bool _sell = dexPair[receiver] || receiver == address(router);
        uint256 _fee = _sell ? sellFee : buyFee;
        uint256 _tax = amount * _fee / 10_000;

        if (_fee > 0) {
            if (_sell) {
                if (sellFeeTeam > 0) _tokensTeam += _tax * sellFeeTeam / _fee;
                if (sellFeeLiqToken > 0) _tokensLiqToken += _tax * sellFeeLiqToken / _fee;
            } else {
                if (buyFeeTeam > 0) _tokensTeam += _tax * buyFeeTeam / _fee;
                if (buyFeeLiqToken > 0) _tokensLiqToken += _tax * buyFeeLiqToken / _fee;
            }
        }

        _balances[address(this)] = _balances[address(this)] + _tax;
        emit Transfer(sender, address(this), _tax);

        return amount - _tax;
    }

    function _sellTaxedTokens() private swapping {
        uint256 _tokens = _tokensTeam + _tokensLiqToken;

        uint256 _liquidityTokensToSwapHalf = _tokensLiqToken / 2;
        uint256 _swapInput = balanceOf(address(this)) - _liquidityTokensToSwapHalf;

        uint256 _balanceSnapshot = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_swapInput, 0, path, address(this), block.timestamp);

        uint256 _tax = address(this).balance - _balanceSnapshot;

        uint256 _taxTeam = _tax * _tokensTeam / _tokens;
        uint256 _taxLiqToken = _tax - _taxTeam;

        _tokensTeam = 0;
        _tokensLiqToken = 0;

        if (_taxTeam > 0) payable(walletTeam).call{value: _taxTeam}("");
        if (_taxLiqToken > 0) router.addLiquidityETH{value: _taxLiqToken}(address(this), _liquidityTokensToSwapHalf, 0, 0, walletLiqToken, block.timestamp);
    }

    function changeDexPair(address _pair, bool _value) external onlyOwner {
        dexPair[_pair] = _value;
    }

    function fetchDexPair(address _pair) external view returns (bool) {
        return dexPair[_pair];
    }

    function changeNoTax(address _wallet, bool _value) external onlyOwner {
        noTax[_wallet] = _value;
    }

    function fetchNoTax(address _wallet) external view returns (bool) {
        return noTax[_wallet];
    }

    function changeNoMax(address _wallet, bool _value) external onlyOwner {
        noMax[_wallet] = _value;
    }

    function fetchNoMax(address _wallet) external view onlyOwner returns (bool) {
        return noMax[_wallet];
    }

    function changeBlacklist(address _wallet, bool _value) external onlyOwner {
        blacklist[_wallet] = _value;
    }

    function fetchBlacklist(address _wallet) external view onlyOwner returns (bool) {
        return blacklist[_wallet];
    }

    function fetchMaxWallet() external view returns (uint256) {
        return maxWallet;
    }

    function changeMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function changeFees(uint256 _buyFeeTeam, uint256 _buyFeeLiqToken, uint256 _sellFeeTeam, uint256 _sellFeeLiqToken) external onlyOwner {
        buyFeeTeam = _buyFeeTeam;
        buyFeeLiqToken = _buyFeeLiqToken;
        buyFee = _buyFeeTeam + _buyFeeLiqToken;
        sellFeeTeam = _sellFeeTeam;
        sellFeeLiqToken = _sellFeeLiqToken;
        sellFee = _sellFeeTeam + _sellFeeLiqToken;
        require(buyFee <= 1000 && sellFee <= 1000);
    }

    function changeWallets(address _walletTeam, address _walletLiqToken) external onlyOwner {
        walletTeam = _walletTeam;
        walletLiqToken = _walletLiqToken;
    }

    function transferETH() external onlyOwner {
        payable(msg.sender).call{value: address(this).balance}("");
    }

    function transferERC(address token) external onlyOwner {
        IERC20 Token = IERC20(token);
        Token.transfer(msg.sender, Token.balanceOf(address(this)));
    }

    receive() external payable {}
}