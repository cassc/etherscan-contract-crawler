/**
 *Submitted for verification at BscScan.com on 2022-09-13
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract RadheKrishna is Context, IERC20, Ownable {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10**18;
    uint256 private _tFeeTotal;

    string private _name = "Radhe Krishna";
    string private _symbol = "RDK";
    uint8 private _decimals = 18;
    
    uint256 _sellTimeInterval;

    /* Section For Set Or Manage Sell Tax */

    address payable public marketingWalletAddress;
    address payable public submarketingWalletAddress;

    uint public _sellreflectionsPer=4;
    uint public _sellburnPer=1;

    uint public _presellreflectionsPer;
    uint public _presellburnPer;

    /* Section For Set Or Manage Buy Tax */

    uint public _buyreflectionsPer=2;   
    uint public _buyburnPer=1;

    uint public _prebuyreflectionsPer;    
    uint public _prebuyburnPer;

    uint public _marketingPer=2;
    uint public _submarketingPer=5;
    uint public _premarketingPer; 
    uint public _presubmarketingPer; 

    /* Minimum & Maximum Transaction Liits */

    uint256 private _maxAntiWhaleLimits;
    uint256 private _minAntiWhaleLimits;

    address[] public reflectionHolders;
    mapping (address => bool) public reflectionpoolEligible;
 
    IUniswapV2Router02 public immutable pancakeRouter;
    address public immutable pancakePair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    uint256 private minTokensBeforeSwap = 5;
    mapping(address => uint256) public myRewards;
    mapping (address => uint) public UserLastSellDetails;
    
    event UpdateMarketingWalletAddress();
    event UpdateSubMarketingWalletAddress();
    event SetSellTimeInterval();
    event BlockWalletAddress();
    event UnblockWalletAddress();
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 marketingFee,
        uint256 subMarketingFee
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
         _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _tOwned[_msgSender()] = _tTotal;
        marketingWalletAddress = payable(_msgSender());
        submarketingWalletAddress= payable(_msgSender());
        IUniswapV2Router02 _pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a pancake pair for this new token
        pancakePair = IUniswapV2Factory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    /* Contarct Owner Can Update The Minimum & Maximum Transaction Limits */
    function update_TransactionLimits(uint256 maxAntiWhaleLimits,uint256 minAntiWhaleLimits) public onlyOwner {
       _maxAntiWhaleLimits=maxAntiWhaleLimits;
       _minAntiWhaleLimits=minAntiWhaleLimits;
    }

    /* Contarct Owner to update the wallet address where marketing fee will recived */
    function update_marketingWalletAddress(address _marketingWalletAddress,address _submarketingWalletAddress) onlyOwner public {
        marketingWalletAddress = payable(_marketingWalletAddress);
        submarketingWalletAddress = payable(_submarketingWalletAddress);
        emit UpdateMarketingWalletAddress();
    }
    /* Contract Owner can set Sell Time Interval */
    function set_sellTimeInterval(uint256 sellTimeInterval) onlyOwner public {
        _sellTimeInterval=sellTimeInterval;
        emit SetSellTimeInterval();
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _verifyBNB() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    function _verifyBEP20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

	function excludeFromReward(address account) public onlyOwner() {        
        require(!_isExcludedFromReward[account], "Account is already excluded");
        _isExcludedFromReward[account] = true;
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");
        _isExcludedFromReward[account] = false;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    bool public limit = true;
    function changeLimit() public onlyOwner(){
        require(limit == true, 'limit is already false');
            limit = false;
    }
    
    function checkSellEligibility(address user) public view returns(bool){
       if(UserLastSellDetails[user]==0) {
           return true;
       }
       else{
           uint noofHour=getHour(UserLastSellDetails[user],getCurrentTimeStamp());
           if(noofHour>=_sellTimeInterval){
               return true;
           }
           else{
               return false;
           }
       }
    }

    function getCurrentTimeStamp() public view returns(uint _timestamp){
       return (block.timestamp);
    }

    function getHour(uint _startDate,uint _endDate) internal pure returns(uint256){
        return ((_endDate - _startDate) / 60 / 60);
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(to == pancakePair){
            require(amount <= _maxAntiWhaleLimits, "BEP20: Sell Qty Exceed !");
            require(amount >= _minAntiWhaleLimits, "BEP20: Sell Qty Does Not Match !"); 
            require(checkSellEligibility(from), "BEP20: Try After Sell Time Interval !"); 
        }
        if(limit ==  true && from != owner() && to != owner()){
            if(to != pancakePair){
                require(((balanceOf(to).add(amount)) <= 500 ether));
            }
                require(amount <= 10000000 ether, 'Transfer amount must be less than 100 tokens');
        }
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        //Sender Reflection Eligibility Status
        //Sender Reflection Eligibility Status

        if(_tOwned[from]>0 && !_isExcludedFromReward[from]) {
            if(!reflectionpoolEligible[from]){
                reflectionpoolEligible[from] = true;
                reflectionHolders.push(from);
            }
        }
        else {
          reflectionpoolEligible[from] = false;
        }

        //Receiver Reflection Eligibility Status
        if(_tOwned[to]>0 && !_isExcludedFromReward[to]) {
            if(!reflectionpoolEligible[to]){
                reflectionpoolEligible[to] = true;
                reflectionHolders.push(to);
            }
        }
        else {
            reflectionpoolEligible[to] = false;
        }   
    
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) 
        {
        //add liquidity
        swapAndLiquify(contractTokenBalance);
        }
        //indicates if fee should be deducted from transfer
        bool takeFee = true;  
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        if(from != pancakePair && to != pancakePair){
            takeFee = false;
        }
        uint TaxType=0; 
        uint256 AlreadyDeducted=0;
        if(from == pancakePair && takeFee==true)  
        {
            TaxType=1;
            //Buy Tax
            uint256 _reflectionsValue = calculateValue(amount,_buyreflectionsPer);
            uint256 _burnValue = calculateValue(amount,_buyburnPer);
            _tTotal = _tTotal.sub(_burnValue);
            _reflection(_reflectionsValue);
            AlreadyDeducted=_burnValue.add(_reflectionsValue);
        }
        if(to == pancakePair && takeFee==true)  
        {
            TaxType=2;
            //Buy Sell
            uint256 _reflectionsValue = calculateValue(amount,_sellreflectionsPer);
            uint256 _burnValue = calculateValue(amount,_sellburnPer);
            _tTotal = _tTotal.sub(_burnValue);
            _reflection(_reflectionsValue);
            AlreadyDeducted=_burnValue.add(_reflectionsValue);
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,AlreadyDeducted,takeFee);
    }

    function _reflection(uint256 _reflectionsValue) internal {
      if(reflectionHolders.length > 0){
      for(uint8 i = 0; i < reflectionHolders.length; i++) {
         address _tokenHolder = reflectionHolders[i];
         if(reflectionpoolEligible[_tokenHolder] && !_isExcludedFromReward[_tokenHolder])
         {
            uint256 _tokenHolderSharePer=(_tOwned[_tokenHolder].mul(100)).div(_tTotal);
            uint256 _tokenHolderShare=_reflectionsValue.mul(_tokenHolderSharePer).div(100);
            _tOwned[_tokenHolder] = _tOwned[_tokenHolder].add(_tokenHolderShare); 
          }
        }
      }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 Balance = address(this).balance;
        // split the contract balance into marketing & sub marketing
        uint256 SubMarketingFee = Balance.mul(_submarketingPer).div(100);
        uint256 MarketingFee = Balance.sub(SubMarketingFee);
        marketingWalletAddress.transfer(MarketingFee);
        submarketingWalletAddress.transfer(SubMarketingFee);      
        emit SwapAndLiquify(contractTokenBalance, Balance, MarketingFee,SubMarketingFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        _approve(address(this), address(pancakeRouter), tokenAmount);
        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,uint256 AlreadyDeducted,bool takeFee) private {
        if(!takeFee)
            removeAllFee();     
        _transferStandard(sender, recipient, amount,AlreadyDeducted);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount,uint256 AlreadyDeducted) private {
        (uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        uint256 NetCredited=tTransferAmount.sub(AlreadyDeducted);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(NetCredited);
        _takeMarketing(tFee);
        _reflectFee(tFee);
        emit Transfer(sender, recipient, NetCredited);
    }

    function _reflectFee(uint256 tFee) private {
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        return (tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingPer).div(100);
    }

    function _takeMarketing(uint256 tMarketing) private {
        _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
    }

    function calculateValue(uint256 _amount,uint256 per) internal pure returns (uint256) {
        return _amount.mul(per).div(100);
    }

    function removeAllFee() private {   
        _prebuyreflectionsPer=_buyreflectionsPer;   
        _prebuyburnPer=_buyburnPer;
        _presellreflectionsPer=_sellreflectionsPer;
        _presellburnPer=_sellburnPer;
        _premarketingPer=_marketingPer;
        _presubmarketingPer=_submarketingPer; 
        _sellreflectionsPer=0;
        _sellburnPer=0;
        _buyreflectionsPer=0;
        _buyburnPer=0;
        _marketingPer=0;
        _submarketingPer=0;    
    }
    
    function restoreAllFee() private {
        _sellreflectionsPer=_presellreflectionsPer;
        _marketingPer=_premarketingPer;
        _submarketingPer=_presubmarketingPer;
        _sellburnPer=_presellburnPer;
        _buyreflectionsPer=_prebuyreflectionsPer;   
        _buyburnPer=_prebuyburnPer;
        _prebuyreflectionsPer=0;    
        _prebuyburnPer=0;
        _presellreflectionsPer=0;
        _premarketingPer=0;
        _presubmarketingPer=0;
        _presellburnPer=0;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

}