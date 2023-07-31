// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

// GINIAI RAIDBOT ROUTER CONTRACT (V1.6)
// created by @giniai
// https://t.me/giniai
// https://twitter.com/AiScheduler
//

// import console
// import "hardhat/console.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private creator;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

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

contract HamstersDepositor is Ownable {
    // modifiers
    modifier onlyCreatorOrOwner() {
        require(
            msg.sender == owner() || whitelist[msg.sender] == true,
            "You are not the creator or whitelisted address for this contract"
        );
        _;
    }
    mapping(address => bool) public whitelist;

    // variables
    address dead = address(0x000000000000000000000000000000000000dEaD);
    address usdToken = address(0x0);
    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor(address uniswapRouter, address _usdToken) {
        transferOwnership(msg.sender);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        uniswapV2Router = _uniswapV2Router;
        usdToken = _usdToken;
    }

    receive() external payable {
        uint256 amountReceived = convertEthToToken(
            usdToken,
            msg.value,
            address(this)
        );
        emit Deposit(usdToken, msg.value, amountReceived, tx.origin);
    }

    event Deposit(
        address indexed tokenAddress,
        uint256 amount,
        uint256 amountReceived,
        address indexed sender
    );

    function WithdrawTokens(
        address tokenAddress,
        uint256 amount
    ) public onlyCreatorOrOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function WithdrawEth(uint256 amount) public onlyCreatorOrOwner {
        payable(owner()).transfer(amount);
    }

    function DepositEth() public payable {
        uint256 amountReceived = convertEthToToken(
            usdToken,
            msg.value,
            address(this)
        );
        emit Deposit(usdToken, msg.value, amountReceived, msg.sender);
    }

    function WithdrawBulkEthToWallets(
        uint256[] memory amounts,
        address[] memory wallets
    ) public onlyCreatorOrOwner {
        for (uint256 i = 0; i < amounts.length; i++) {
            payable(wallets[i]).transfer(amounts[i]);
        }
    }

    // withdraw bulk tokens to wallets
    function WithdrawBulkTokensToWallets(
        address tokenAddress,
        uint256[] memory amounts,
        address[] memory wallets
    ) public onlyCreatorOrOwner {
        for (uint256 i = 0; i < amounts.length; i++) {
            IERC20(tokenAddress).transfer(wallets[i], amounts[i]);
        }
    }

    // convert eth to tokens and send to wallet
    function convertEthToToken(
        address tokenAddress,
        uint256 amount,
        address wallet
    ) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;
        // get balance currently of BUSD
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, wallet, block.timestamp + 3600);
        // get balance after
        uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
        // get the difference
        uint256 balanceDiff = balanceAfter - balanceBefore;
        // send the difference to the wallet
        return balanceDiff;
    }

    // add whitelisted address
    function editWhitelistAddress(
        address _address,
        bool valid
    ) public onlyOwner {
        whitelist[_address] = valid;
    }

    function changeUsdToken(address _usdToken) public onlyCreatorOrOwner {
        usdToken = _usdToken;
    }
}