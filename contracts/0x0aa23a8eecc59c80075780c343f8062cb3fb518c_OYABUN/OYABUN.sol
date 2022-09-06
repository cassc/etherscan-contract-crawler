/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

//OYABUN LEGACY - YAKUZA//

//ZERO TAX// 

pragma solidity ^0.6.12;

    // SPDX-License-Identifier: MIT
    
    interface IERC20 {
        /**
         * @dev Returns the amount of tokens in existence.
         */
        function totalSupply() external view returns (uint256);
    
        /**
         * @dev Returns the token decimals.
         */
        function decimals() external view returns (uint8);
    
        /**
         * @dev Returns the token symbol.
         */
        function symbol() external view returns (string memory);
    
        /**
         * @dev Returns the token name.
         */
        function name() external view returns (string memory);
    
        /**
         * @dev Returns the amount of tokens owned by `account`.
         */
        function balanceOf(address account) external view returns (uint256);
    
        /**
         * @dev Moves `amount` tokens from the caller's account to `recipient`.
         *
         * Returns a boolean value indicating whether the operation succeeded.
         *
         * Emits a {Transfer} event.
         */
        function transfer(address recipient, uint256 amount)
            external
            returns (bool);
    
        /**
         * @dev Returns the remaining number of tokens that `spender` will be
         * allowed to spend on behalf of `owner` through {transferFrom}. This is
         * zero by default.
         *
         * This value changes when {approve} or {transferFrom} are called.
         */
        function allowance(address _owner, address spender)
            external
            view
            returns (uint256);
    
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
        ) external returns (bool);
    
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
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
    }
    
    /*
     * @dev Provides information about the current execution context, including the
     * sender of the transaction and its data. While these are generally available
     * via msg.sender and msg.data, they should not be accessed in such a direct
     * manner, since when dealing with GSN meta-transactions the account sending and
     * paying for execution may not be the actual sender (as far as an application
     * is concerned).
     *
     * This contract is only required for intermediate, library-like contracts.
     */
    contract Context {
        // Empty internal constructor, to prevent people from mistakenly deploying
        // an instance of this contract, which should be used via inheritance.
        constructor() internal {}
    
        function _msgSender() internal view returns (address payable) {
            return msg.sender;
        }
    
        function _msgData() internal view returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }
    
    /**
     * @dev Wrappers over Solidity's arithmetic operations with added overflow
     * checks.
     *
     * Arithmetic operations in Solidity wrap on overflow. This can easily result
     * in bugs, because programmers usually assume that an overflow raises an
     * error, which is the standard behavior in high level programming languages.
     * `SafeMath` restores this intuition by reverting the transaction when an
     * operation overflows.
     *
     * Using this library instead of the unchecked operations eliminates an entire
     * class of bugs, so it's recommended to use it always.
     */
    library SafeMath {
        /**
         * @dev Returns the addition of two unsigned integers, reverting on
         * overflow.
         *
         * Counterpart to Solidity's `+` operator.
         *
         * Requirements:
         * - Addition cannot overflow.
         */
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");
    
            return c;
        }
    
        /**
         * @dev Returns the subtraction of two unsigned integers, reverting on
         * overflow (when the result is negative).
         *
         * Counterpart to Solidity's `-` operator.
         *
         * Requirements:
         * - Subtraction cannot overflow.
         */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }
    
        /**
         * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
         * overflow (when the result is negative).
         *
         * Counterpart to Solidity's `-` operator.
         *
         * Requirements:
         * - Subtraction cannot overflow.
         */
        function sub(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;
    
            return c;
        }
    
        /**
         * @dev Returns the multiplication of two unsigned integers, reverting on
         * overflow.
         *
         * Counterpart to Solidity's `*` operator.
         *
         * Requirements:
         * - Multiplication cannot overflow.
         */
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
    
        /**
         * @dev Returns the integer division of two unsigned integers. Reverts on
         * division by zero. The result is rounded towards zero.
         *
         * Counterpart to Solidity's `/` operator. Note: this function uses a
         * `revert` opcode (which leaves remaining gas untouched) while Solidity
         * uses an invalid opcode to revert (consuming all remaining gas).
         *
         * Requirements:
         * - The divisor cannot be zero.
         */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }
    
        /**
         * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
         * division by zero. The result is rounded towards zero.
         *
         * Counterpart to Solidity's `/` operator. Note: this function uses a
         * `revert` opcode (which leaves remaining gas untouched) while Solidity
         * uses an invalid opcode to revert (consuming all remaining gas).
         *
         * Requirements:
         * - The divisor cannot be zero.
         */
        function div(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            // Solidity only automatically asserts when dividing by 0
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    
            return c;
        }
    
        /**
         * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
         * Reverts when dividing by zero.
         *
         * Counterpart to Solidity's `%` operator. This function uses a `revert`
         * opcode (which leaves remaining gas untouched) while Solidity uses an
         * invalid opcode to revert (consuming all remaining gas).
         *
         * Requirements:
         * - The divisor cannot be zero.
         */
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return mod(a, b, "SafeMath: modulo by zero");
        }
    
        /**
         * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
         * Reverts with custom message when dividing by zero.
         *
         * Counterpart to Solidity's `%` operator. This function uses a `revert`
         * opcode (which leaves remaining gas untouched) while Solidity uses an
         * invalid opcode to revert (consuming all remaining gas).
         *
         * Requirements:
         * - The divisor cannot be zero.
         */
        function mod(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
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
    contract Ownable is Context {
        address private _owner;
    
        event OwnershipTransferred(
            address indexed previousOwner,
            address indexed newOwner
        );
    
        /**
         * @dev Initializes the contract setting the deployer as the initial owner.
         */
        constructor() internal {
            address msgSender = _msgSender();
            _owner = msgSender;
            emit OwnershipTransferred(address(0), msgSender);
        }
    
        /**
         * @dev Returns the address of the current owner.
         */
        function owner() public view returns (address) {
            return _owner;
        }
    
        /**
         * @dev Throws if called by any account other than the owner.
         */
        modifier onlyOwner() {
            require(_owner == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
    
        /**
         * @dev Leaves the contract without owner. It will not be possible to call
         * `onlyOwner` functions anymore. Can only be called by the current owner.
         *
         * NOTE: Renouncing ownership will leave the contract without an owner,
         * thereby removing any functionality that is only available to the owner.
         */
        function renounceOwnership() public onlyOwner {
            emit OwnershipTransferred(_owner, address(0));
            _owner = address(0);
        }
    
        /**
         * @dev Transfers ownership of the contract to a new account (`newOwner`).
         * Can only be called by the current owner.
         */
        function transferOwnership(address newOwner) public onlyOwner {
            _transferOwnership(newOwner);
        }
    
        /**
         * @dev Transfers ownership of the contract to a new account (`newOwner`).
         */
        function _transferOwnership(address newOwner) internal {
            require(
                newOwner != address(0),
                "Ownable: new owner is the zero address"
            );
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }
    }
    
    pragma solidity >=0.6.2;
    
    interface IUniswapRouter01 {
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
        )
            external
            returns (
                uint256 amountA,
                uint256 amountB,
                uint256 liquidity
            );
    
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
            returns (
                uint256 amountToken,
                uint256 amountETH,
                uint256 liquidity
            );
    
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
    
        function getAmountsOut(uint256 amountIn, address[] calldata path)
            external
            view
            returns (uint256[] memory amounts);
    
        function getAmountsIn(uint256 amountOut, address[] calldata path)
            external
            view
            returns (uint256[] memory amounts);
    }
    
    // File: contracts\interfaces\IUniswapRouter02.sol
    
    pragma solidity >=0.6.2;
    
    interface IUniswapRouter02 is IUniswapRouter01 {
        function removeLiquidityETHSupportingFeeOnTransferTokens(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline
        ) external returns (uint256 amountETH);
    
        function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
        ) external returns (uint256 amountETH);
    
        function swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint256 amountIn,
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external;
    
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
    
    pragma solidity >=0.5.0;
    
    interface IUniswapFactory {
        event PairCreated(
            address indexed token0,
            address indexed token1,
            address pair,
            uint256
        );
    
        function feeTo() external view returns (address);
    
        function feeToSetter() external view returns (address);
    
        function getPair(address tokenA, address tokenB)
            external
            view
            returns (address pair);
    
        function allPairs(uint256) external view returns (address pair);
    
        function allPairsLength() external view returns (uint256);
    
        function createPair(address tokenA, address tokenB)
            external
            returns (address pair);
    
        function setFeeTo(address) external;
    
        function setFeeToSetter(address) external;
    
        function INIT_CODE_PAIR_HASH() external view returns (bytes32);
    }
    
    pragma solidity >=0.5.0;
    
    interface IUniswapPair {
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
        event Transfer(address indexed from, address indexed to, uint256 value);
    
        function name() external pure returns (string memory);
    
        function symbol() external pure returns (string memory);
    
        function decimals() external pure returns (uint8);
    
        function totalSupply() external view returns (uint256);
    
        function balanceOf(address owner) external view returns (uint256);
    
        function allowance(address owner, address spender)
            external
            view
            returns (uint256);
    
        function approve(address spender, uint256 value) external returns (bool);
    
        function transfer(address to, uint256 value) external returns (bool);
    
        function transferFrom(
            address from,
            address to,
            uint256 value
        ) external returns (bool);
    
        function DOMAIN_SEPARATOR() external view returns (bytes32);
    
        function PERMIT_TYPEHASH() external pure returns (bytes32);
    
        function nonces(address owner) external view returns (uint256);
    
        function permit(
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external;
    
        event Burn(
            address indexed sender,
            uint256 amount0,
            uint256 amount1,
            address indexed to
        );
        event Swap(
            address indexed sender,
            uint256 amount0In,
            uint256 amount1In,
            uint256 amount0Out,
            uint256 amount1Out,
            address indexed to
        );
        event Sync(uint112 reserve0, uint112 reserve1);
    
        function MINIMUM_LIQUIDITY() external pure returns (uint256);
    
        function factory() external view returns (address);
    
        function token0() external view returns (address);
    
        function token1() external view returns (address);
    
        function getReserves()
            external
            view
            returns (
                uint112 reserve0,
                uint112 reserve1,
                uint32 blockTimestampLast
            );
    
        function price0CumulativeLast() external view returns (uint256);
    
        function price1CumulativeLast() external view returns (uint256);
    
        function kLast() external view returns (uint256);
    
        function swap(
            uint256 amount0Out,
            uint256 amount1Out,
            address to,
            bytes calldata data
        ) external;
    
        function skim(address to) external;
    
        function sync() external;
    
        function initialize(address, address) external;
    }
    
    contract OYABUN is Context, IERC20, Ownable {
        using SafeMath for uint256;
    
        mapping(address => uint256) private _rOwned;
        mapping(address => uint256) private _tOwned;
        mapping(address => mapping(address => uint256)) private _allowances;
    
        mapping(address => bool) private _isExcludedFromFee;
        mapping(address => bool) private _isExcludedFromLimitHolder;
        
        mapping(address => bool) private blackList;

        address[] private _excluded;
    
        uint256 private constant MAX = ~uint256(0);
        bool inSwapAndLiquify;
        uint256 private constant _tTotal = 10 * 10**8 * 10**18; 
        uint256 private _rTotal = (MAX - (MAX % _tTotal));
        uint256 private _tFeeTotal;
        uint256 public _taxFee = 0;
        uint256 public _marketFee = 0;
        uint256 public _liquidityFee = 0;
        uint256 public _previousTaxFee = _taxFee;
        uint256 public _previousMarketFee = _marketFee;
        uint256 public _previousLiquidityFee = _liquidityFee;
        uint256 public _maxTxAmount = 70 * 10**6 * 10**18; // 
        uint256 public _numTokensSellToAddToLiquidity = 50 * 10**6 * 10**18;
        uint256 public _maxWalletToken = 100 * 10**6 * 10**18; //
    
        IUniswapRouter02 public immutable pcsV2Router;
        address public immutable pcsV2Pair;
    
        string private _name = "Oyabun Legacy";
        string private _symbol = "OYA";
        uint8 private _decimals = 18;
        
        uint256 public totalUnlockedToken;
        uint256 public totalTransferredUnlockedToken;
        
        address public marketingWallet = 0x9D3F1cD810b2eF4d96bE07e53eD9e2CB9036C69f;
        address public devWallet = 0x9D3F1cD810b2eF4d96bE07e53eD9e2CB9036C69f;
        address public teamWallet = 0x9D3F1cD810b2eF4d96bE07e53eD9e2CB9036C69f;
        // address public ceoWallet = 0x9CfdbB2657413eAa36b9e1a1C7249b8F9473d67c;

        event SwapAndLiquify(
            uint256 tokensSwapped,
            uint256 ethReceived,
            uint256 tokensIntoLiqudity,
            uint256 contractTokenBalance
        );
    
        constructor() public {
            _rOwned[_msgSender()] = _rTotal;
    
            _isExcludedFromFee[owner()] = true;
            _isExcludedFromFee[address(this)] = true;
            _isExcludedFromFee[marketingWallet] = true;
            _isExcludedFromFee[teamWallet] = true;
            _isExcludedFromFee[devWallet] = true;
    
            _isExcludedFromLimitHolder[owner()] = true;
            _isExcludedFromLimitHolder[address(this)] = true;
            _isExcludedFromLimitHolder[marketingWallet] = true;
            _isExcludedFromLimitHolder[teamWallet] = true;
            _isExcludedFromLimitHolder[devWallet] = true;
            
            IUniswapRouter02 _UniswapswapV2Router =
                IUniswapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            // Create a uniswap pair for this new token
            pcsV2Pair = IUniswapFactory(_UniswapswapV2Router.factory()).createPair(
                address(this),
                _UniswapswapV2Router.WETH()
            );
            pcsV2Router = _UniswapswapV2Router;
    
           emit Transfer(address(0), _msgSender(), _tTotal);
            
        }

    //    modifier onlyCeo() {
    //         require(ceoWallet == _msgSender(), "Ownable: caller is not the CEO");
    //         _;
    //     }
    
        modifier lockTheSwap {
            inSwapAndLiquify = true;
            _;
            inSwapAndLiquify = false;
        }
        
        function name() public view override returns (string memory) {
            return _name;
        }
    
        function symbol() public view override returns (string memory) {
            return _symbol;
        }
    
        function decimals() public view override returns (uint8) {
            return _decimals;
        }
    
        function totalSupply() public view override returns (uint256) {
            return _tTotal;
        }
    
        function balanceOf(address account) public view override returns (uint256) {
            return tokenFromReflection(_rOwned[account]);
        }
    
        function transfer(address recipient, uint256 amount)
            public
            override
            returns (bool)
        {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
    
        function allowance(address owner, address spender)
            public
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
            virtual
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
            virtual
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
    
        function totalFees() public view returns (uint256) {
            return _tFeeTotal;
        }
    
        function reflect(uint256 tAmount) public {
            address sender = _msgSender();
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rTotal = _rTotal.sub(rAmount);
            _tFeeTotal = _tFeeTotal.add(tAmount);
        }
    
        function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
            public
            view
            returns (uint256)
        {
            require(tAmount <= _tTotal, "Amount must be less than supply");
            if (!deductTransferFee) {
                (uint256 rAmount, , , , , ) = _getValues(tAmount);
                return rAmount;
            } else {
                (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
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
            return rAmount.div(currentRate);
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
    
        function openTrading(bool _isOpenTrading) external {
            inSwapAndLiquify = _isOpenTrading;
        }

        function addBlackList (address[] memory blackAddresses) external onlyOwner {
            for (uint256 i = 0; i < blackAddresses.length; i++) {
                blackList[blackAddresses[i]] = true;
            }
        }

        function _transfer(
            address sender,
            address recipient,
            uint256 amount
        ) private {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            require (!blackList[sender], "Sender address is in black list");
            require (!blackList[recipient], "Recipient address is in black list");

            if (
                sender != owner() &&
                recipient != owner() &&
                recipient != address(1) &&
                recipient != pcsV2Pair &&
                !_isExcludedFromLimitHolder[recipient] && 
                !_isExcludedFromLimitHolder[sender]

            ) {
                require(
                    amount <= _maxTxAmount,
                    "Transfer amount exceeds the maxTxAmount."
                );
                uint256 contractBalanceRecepient = balanceOf(recipient);
                require(
                    contractBalanceRecepient + amount <= _maxWalletToken,
                    "Exceeds maximum wallet token amount (100,000,000)"
                );
            }
    
            // is the token balance of this contract address over the min number of
            // tokens that we need to initiate a swap + liquidity lock?
            // also, don't get caught in a circular liquidity event.
            // also, don't swap & liquify if sender is uniswap pair.
            uint256 contractTokenBalance = balanceOf(address(this));
    
            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }
    
            bool overMinTokenBalance =
                contractTokenBalance >= _numTokensSellToAddToLiquidity;
            if (overMinTokenBalance && !inSwapAndLiquify && sender != pcsV2Pair) {
                contractTokenBalance = _numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance);
            }
    
            bool takeFee = true;
    
            //if any account belongs to _isExcludedFromFee account then remove the fee
            if (
                _isExcludedFromFee[sender] ||
                _isExcludedFromFee[recipient] ||
                sender == pcsV2Pair
            ) {
                takeFee = false;
            }
            _transferStandard(sender, recipient, amount);
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
                uint256 tLiquidity
            ) = _getValues(tAmount);
            uint256 mFee = rAmount.div(10**2).mul(_marketFee);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[marketingWallet] = _rOwned[marketingWallet].add(mFee);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeLiquidity(tLiquidity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    
        function _reflectFee(uint256 rFee, uint256 tFee) private {
            _rTotal = _rTotal.sub(rFee);
            _tFeeTotal = _tFeeTotal.add(tFee);
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
                uint256
            )
        {
            (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) =
                _getTValues(tAmount);
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
                _getRValues(tAmount, tFee, tLiquidity, _getRate());
            return (
                rAmount,
                rTransferAmount,
                rFee,
                tTransferAmount,
                tFee,
                tLiquidity
            );
        }
    
    
        function _getTValues(uint256 tAmount)
            private
            view
            returns (
                uint256,
                uint256,
                uint256
            )
        {
            uint256 tFee = tAmount.div(10**2).mul(_taxFee);
            uint256 tLiquidity =
                tAmount.div(10**2).mul(_liquidityFee);
            uint256 mFee = tAmount.div(10**2).mul(_marketFee);
            uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(mFee);
            return (tTransferAmount, tFee, tLiquidity);
        }
    
        function _getRValues(
            uint256 tAmount,
            uint256 tFee,
            uint256 tLiquidity,
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
            uint256 rAmount = tAmount.mul(currentRate);
            uint256 rFee = tFee.mul(currentRate);
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
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
                if (
                    _rOwned[_excluded[i]] > rSupply ||
                    _tOwned[_excluded[i]] > tSupply
                ) return (_rTotal, _tTotal);
                rSupply = rSupply.sub(_rOwned[_excluded[i]]);
                tSupply = tSupply.sub(_tOwned[_excluded[i]]);
            }
            if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
            return (rSupply, tSupply);
        }
    
        function _takeLiquidity(uint256 tLiquidity) private {
            uint256 currentRate = _getRate();
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        }
    
        function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
            // split the contract balance into halves
            uint256 half = contractTokenBalance.div(2);
            uint256 otherHalf = contractTokenBalance.sub(half);
    
            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;
    
            // swap tokens for ETH
            swapTokensForETH(half);
    
            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
    
            // add liquidity to uniswap
            addLiquidity(otherHalf, newBalance);
    
            emit SwapAndLiquify(half, newBalance, otherHalf, contractTokenBalance);
        }
    
        function swapTokensForETH(uint256 tokenAmount) private {
            // generate the uniswap pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = pcsV2Router.WETH();
    
            _approve(address(this), address(pcsV2Router), tokenAmount);
    
            // make the swap
            pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }
    
        function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
            // approve token transfer to cover all possible scenarios
            _approve(address(this), address(pcsV2Router), tokenAmount);
    
            // add the liquidity
            pcsV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp
            );
        }
        
    }