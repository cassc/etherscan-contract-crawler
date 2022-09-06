/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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



contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract Migration is Ownable {
    IERC20 public token1; // V1 token
    IERC20 public token2; // V2 token
    uint256 public immutable token1TotalSupply;
    uint256 public immutable token2TotalSupply;
    
    bool public isInitialized = false;
    bool public finalized = false;
    uint256 public bridgeTime;
    uint256 public exchangeEndTime;

    address public immutable liquidityWalletForV2;
    
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    
    uint256 private _status;
        
    // pay close attention here and make sure all values are CORRECT
    
    constructor() {
        _status = _NOT_ENTERED;
        
        // Token V1
        token1 = IERC20(address(0x4B88Fe1658503897005a4e2a90F8B257Fd304e0E));
        
        // Token V2 -- will be updated to new Contract once live
        token2 = IERC20(address(0x5e579Ec235C76f746fE570B9cde02d64E559fadF));  // UPDATE
        
        // change to token owner or liquidity holder (usually the project owner, not the developer) before launch
        liquidityWalletForV2 = address(0x471999CA77C5DF2ae1A51AB5d719123CF05047e1);  // UPDATE
        
        // set duration of bridge AFTER initialize is called
        bridgeTime = 2 days;
          
        // This just grabs total supply from each token, to ensure the ratio for the swap is correct.
        token1TotalSupply = token1.totalSupply();
        token2TotalSupply = token2.totalSupply();
    }
    
    receive() external payable {
    }
    
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    
    function tradeInTokens() external nonReentrant {
        uint256 tradingRatio = 0;
        uint256 amountToSend;
        require(isInitialized, "Trading bridge is not active");
        require(!finalized, "Bridging tokens is not allowed after bridge is complete");
        uint256 token1Balance = token1.balanceOf(msg.sender);
        require(token1.allowance(msg.sender, address(this)) >= token1Balance, "Approval must be done before transfer");
        token1.transferFrom(msg.sender, address(liquidityWalletForV2), token1Balance); // tokens are sent directly to owner wallet.
        
        // determine the trading ratio if swapping between tokens of differing supplies. (1% = 1% as an example)
        if(token2TotalSupply > token1TotalSupply){
            tradingRatio = token2TotalSupply / token1TotalSupply;
            amountToSend = token1Balance * tradingRatio; // multiply if V2 supply is higher than V1
        } else if (token1TotalSupply > token2TotalSupply){
            tradingRatio = token1TotalSupply / token2TotalSupply;
            amountToSend = token1Balance / tradingRatio; // divide if V2 supply is lower than V1
        } else if (token1TotalSupply == token2TotalSupply) {
            amountToSend = token1Balance; // leave alone if supply is identical
        }
        
        require(token2.balanceOf(address(this)) >= amountToSend, "Not enough V2 tokens to send");
        token2.transfer(msg.sender, amountToSend);
    }

    
    function initialize() external onlyOwner {
        require(!isInitialized, "May not initialize contract again to prevent moving out exchangeEndTime");
        isInitialized = true;
        exchangeEndTime = block.timestamp + bridgeTime; // finalize can only be called after this many days
    }
    
    function finalize() external onlyOwner {
        require(block.timestamp >= exchangeEndTime, "Bridge not over yet.");
        if(token1.balanceOf(address(this)) > 0){
            token1.transfer(address(msg.sender),token1.balanceOf(address(this)));
        }
        if(token2.balanceOf(address(this)) > 0){
            token2.transfer(address(msg.sender),token2.balanceOf(address(this)));
        }
    }
    
    // Feel free to remove the next two functions if you are positive there will be no contract issues but this does give a way to prevent tokens from getting locked forever in the event the contract itself is screwed up.
    
    function emergencyToken2Withdraw() external onlyOwner {
        token2.transfer(address(msg.sender),token2.balanceOf(address(this)));
    }
    
    // use in case the sell won't work.
    function emergencyToken1Withdraw() external onlyOwner {
        token1.transfer(address(msg.sender),token1.balanceOf(address(this)));
    }

    function emergencyUpdateToken1(address token) external onlyOwner {
        token1 = IERC20(token);
    }

    function emergencyToken2Withdraw(address token) external onlyOwner {
        token2 = IERC20(token);
    }
}