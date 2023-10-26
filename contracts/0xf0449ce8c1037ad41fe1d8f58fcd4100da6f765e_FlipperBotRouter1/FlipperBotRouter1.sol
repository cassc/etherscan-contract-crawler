/**
 *Submitted for verification at Etherscan.io on 2023-10-10
*/

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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: contracts/FlipperBotRouter.sol


pragma solidity 0.8.21;

// import OZ ownable


interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
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

    function WETH() external pure returns (address);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract FlipperBotRouter1 is Ownable {
    uint256 public tradingFee = 50; // 0.5% fee

    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function setTradingFee(uint256 _tradingFee) public onlyOwner {
        tradingFee = _tradingFee;
    }

    receive() external payable {}

    function withdrawFees() public onlyOwner {
        // Send using call
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function calculateAmountInWithTaxDeducted(
        uint256 amountIn
    ) public view returns (uint256) {
        return amountIn - ((amountIn * tradingFee) / 10000);
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) public view returns (uint256[] memory) {
        return router.getAmountsOut(amountIn, path);
    }

    function performBuyOrder(
        uint _amountOutMin,
        address tokenAddress
    ) public payable {
        uint256 amountIn = msg.value;
        uint256 amountInMinusFee = calculateAmountInWithTaxDeducted(amountIn);

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountInMinusFee
        }(_amountOutMin, path, msg.sender, block.timestamp + 3600);
    }

    function performSellOrder(
        uint _amountIn,
        uint _amountOutMin,
        address tokenAddress
    ) public {
        IERC20 token = IERC20(tokenAddress);
        // uint256 tokenBalance = token.balanceOf(msg.sender);
        // require(tokenBalance >= _amountIn, "Not enough tokens in wallet");

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = router.WETH();

        token.transferFrom(msg.sender, address(this), _amountIn);
        token.approve(address(router), _amountIn);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            block.timestamp + 3600
        );

        uint256 contractEthBalance = address(this).balance;

        // Send it to msg.sender
        (bool success, ) = msg.sender.call{
            value: calculateAmountInWithTaxDeducted(contractEthBalance)
        }("");
    }
}