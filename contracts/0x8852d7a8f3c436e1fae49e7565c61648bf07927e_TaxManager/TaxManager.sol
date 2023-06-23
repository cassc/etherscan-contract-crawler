/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: TaxManager.sol


pragma solidity 0.8.20;
// OpenZeppelin


// Uniswap interfaces




// This contract operates as an external executor for collecting, liquidating, and distributing token taxes
// Able to be used for multiple tokens at a time. Only supports a single recipient per token currently.
// For multiple recipients, use a splitter contract as the recipient of a token's taxes
contract TaxManager is Ownable {
    /// Global Vars
    IUniswapV2Router02 public uniswapV2Router;

    /// Structs
    struct RegisteredToken {
        address recipient;
        uint8 feeWeight; // Weight out of 1000. Eg 10 = 1%
    }

    /// Address Mappings
    mapping(address => bool) private executors; // List of addresses that can call tax handling functions
    mapping(address => RegisteredToken) public registeredTokens; // Token/Recipient data

    /// Modifiers
    modifier onlyExecutor {
        require(executors[msg.sender], "Address is not a contract executor");
        _;
    }
    constructor () {
        executors[msg.sender] = true; // Makes deployer a executor
        // Initialize uniswap router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
    }

    /// Executor Functions

    /** Withdraws tokens from the token contract
    Note: REQUIRES AN ALLOWANCE on this contract **/
    function pullBalance (address tokenAddress, uint256 tokenAmount) external onlyExecutor {
        _pullBalance(tokenAddress, tokenAmount);
    }
    function _pullBalance(address tokenAddress, uint256 tokenAmount) private {
        if (tokenAmount == 0 ) // Default to entire balance if not specified
            tokenAmount = IERC20(tokenAddress).balanceOf(tokenAddress); 
        if (tokenAmount > 0) { // The target contract has a balance we can collect
            require(IERC20(tokenAddress).allowance(tokenAddress, address(this)) >= tokenAmount, "Insufficient token allowance");
            IERC20(tokenAddress).transferFrom(tokenAddress, address(this), tokenAmount);
        } // else we don't have anything to pull
    }

    /** Liquidate Taxes for a single token balance **/
    function processBalance(address tokenAddress, uint256 tokenAmount, uint256 minimumAmountOut) external onlyExecutor {
        _processBalance(tokenAddress, tokenAmount, minimumAmountOut);
    }
    function _processBalance(address tokenAddress, uint256 tokenAmount, uint256 minimumAmountOut) private {
        if (tokenAmount == 0)
            tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
        if (tokenAmount > 0) {
            // Uniswap logic here. Replace with liquidity/other as needed
            _swapTokensForEth(tokenAddress, tokenAmount, minimumAmountOut); // Uniswap: Liquidate tokens
        } // else there are no tokens to process
    }
    /** Distribute ETH to recipient, minus any processing fees
    The keepFee boolean allows executor bots to decide between collecting the fee or forwarding it to the owner **/
    function handleETH(address tokenAddress, bool keepFee) external onlyExecutor {
        _handleETH(tokenAddress, keepFee);
    }
    function _handleETH(address tokenAddress, bool keepFee) private {
        uint256 contractBalance = address(this).balance;
        if (contractBalance > 0 ) {
            address recipient = registeredTokens[tokenAddress].recipient;
            require(recipient != address(0), "Unregistered token");
            uint256 feeWeight = registeredTokens[tokenAddress].feeWeight;
            uint256 ethAmount = contractBalance * (1000-feeWeight) / 1000;
            uint256 feeAmount = contractBalance * (feeWeight) / 1000;

            payable(recipient).transfer(ethAmount);
            if (keepFee) {
                payable(msg.sender).transfer(feeAmount);
            } else {
                payable(owner()).transfer(feeAmount);
            }

        } // else there is no eth to handle
    }
    /** Wrapper function to chain multiple transactions **/
    function manageTaxes(address tokenAddress, uint256 pullTokenAmount, uint256 processTokenAmount, uint256 processMinAmountOut, bool keepFee) external onlyExecutor {
        _pullBalance(tokenAddress, pullTokenAmount);
        _processBalance(tokenAddress, processTokenAmount, processMinAmountOut);
        _handleETH(tokenAddress, keepFee);
    }
    /// End Executor Functions


    /// Owner Functions

    /** Update Executor status **/
    function updateExecutor(address _executor, bool _state) external onlyOwner {
        require(executors[_executor] != _state, "Executor status already set");
        executors[_executor] = _state;
    }
    /** Add/remove managed token **/
    function registerToken(address _token, address _recipient, uint8 _weight, bool _approveRouter) external onlyOwner {
        require(_recipient != address(0), "Must specify a tax recipient");
        require(_weight <= 1000, "Maximum weight is 1000");
        registeredTokens[_token].recipient = _recipient;
        registeredTokens[_token].feeWeight = _weight;
        if (_approveRouter)
            IERC20(_token).approve(address(uniswapV2Router), 2**254);
    }
    /** Update fee **/
    function updateFeeWeight(address _token, uint8 _weight) external onlyOwner {
        require(_weight <= 1000, "Maximum weight is 1000");
        registeredTokens[_token].feeWeight = _weight;
    }
    /** Update fee recipient **/
    function updateRecipient(address _token, address _recipient) external onlyOwner {
        require(_recipient != address(0), "Must specify a tax recipient");
        registeredTokens[_token].recipient = _recipient;
    }

    /** Remove token from registry **/
    function unregisterToken(address _token) external onlyOwner {
        delete registeredTokens[_token];
    }

    /** Emergency withdraw for ETH left in contract **/
    function withdrawETH(uint256 amount) external onlyOwner {
        if ( amount == 0 )
            amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    /** Emergency withdraw for tokens left in contract **/
    function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner {
        if ( amount == 0 )
            amount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(owner(), amount);
    }
    /// End Owner Functions


    /// Uniswap V2 Functions
    /** Grant token approval on another contract
    Mainly useful for allowing liquidation on uniswap, not normally needed otherwise **/
    function approveExternal(address tokenAddress, address externalContract, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).approve(externalContract, tokenAmount);
    }
    /** Liquidate tokens into ETH, ignoring any slippage **/
    function _swapTokensForEth(address tokenAddress, uint256 tokenAmount, uint256 minimumAmountOut) private {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            minimumAmountOut,
            path,
            address(this),
            block.timestamp
        );
    }

    /// End Uniswap V2 Functions
    
    // fallbacks
    receive() external payable {}
    fallback() external payable {}
}