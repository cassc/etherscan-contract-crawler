/**
 *Submitted for verification at BscScan.com on 2023-03-14
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// File: AutoBuyTokens.sol


// token swap contract

pragma solidity ^0.8.0;



//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


//import the PancakeSwap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IPancakeRouter02 {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
  
  function WETH() external pure returns (address);
}

interface IPancakePair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IPancakeFactory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}


contract AutoBuyToken is Ownable, ReentrancyGuard {
    address public tokenAddress;
    IERC20 public token;
    IPancakeRouter02 public pancakeRouter;
    uint256 public amountToSpend;
    uint256 public buyTime;
    uint256 public lastPurchaseTime;
    bool public autoBuyEnabled;
    mapping(address => bool) authorized;

    constructor(address _tokenAddress, uint256 _amountToSpend, uint256 _buyTime) {
        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
        amountToSpend = _amountToSpend;
        buyTime = _buyTime;
        lastPurchaseTime = block.timestamp;
        autoBuyEnabled = false;
        pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);  // mainnet router address
    }

    function startAutoBuy() external onlyOwner {
        autoBuyEnabled = true;
    }

    function stopAutoBuy() external onlyOwner {
        autoBuyEnabled = false;
    }

    function buyToken() external nonReentrant {
    require(authorized[msg.sender] || autoBuyEnabled, "Sender not authorized to buy token");
    require(block.timestamp >= lastPurchaseTime + buyTime, "Cannot buy token yet");
    require(token.balanceOf(address(this)) >= amountToSpend, "Insufficient balance to buy token");
    
    // Approve PancakeSwap router to spend token on behalf of contract for the amountToSpend
    token.approve(address(pancakeRouter), amountToSpend);

    // Buy the token on PancakeSwap
    address[] memory path = new address[](2);
    path[0] = pancakeRouter.WETH();
    path[1] = tokenAddress;
    pancakeRouter.swapExactTokensForTokens(amountToSpend, 0, path, address(this), block.timestamp + 3600);

    // Update last purchase time
    lastPurchaseTime = block.timestamp;
}

function withdrawTokens() external onlyOwner nonReentrant {
    uint256 tokenBalance = token.balanceOf(address(this));
    require(tokenBalance > 0, "No tokens to withdraw");
    require(token.transfer(msg.sender, tokenBalance), "Transfer failed");
}

function depositBNB() external payable onlyOwner {
}

function addAuthorized(address _address) external onlyOwner {
    authorized[_address] = true;
}

function removeAuthorized(address _address) external onlyOwner {
    authorized[_address] = false;
}

function setAmountToSpend(uint256 _amountToSpend) external onlyOwner {
    amountToSpend = _amountToSpend;
}

function setBuyTime(uint256 _buyTime) external onlyOwner {
    buyTime = _buyTime;
}

function setPancakeRouterAddress(address _routerAddress) external onlyOwner {
    require(_routerAddress != address(0), "Invalid router address");
    pancakeRouter = IPancakeRouter02(_routerAddress);
}


function buyTokenNow() external onlyOwner nonReentrant {
    require(token.balanceOf(address(this)) >= amountToSpend, "Insufficient balance to buy token");

    // Approve PancakeSwap router to spend token on behalf of contract for the amountToSpend
    token.approve(address(pancakeRouter), amountToSpend);

    // Buy the token on PancakeSwap
    address[] memory path = new address[](2);
    path[0] = pancakeRouter.WETH();
    path[1] = tokenAddress;
    pancakeRouter.swapExactTokensForTokens(amountToSpend, 0, path, address(this), block.timestamp + 3600);

    // Update last purchase time
    lastPurchaseTime = block.timestamp;
}
}