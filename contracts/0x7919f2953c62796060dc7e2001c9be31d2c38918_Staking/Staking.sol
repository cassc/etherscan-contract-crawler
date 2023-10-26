/**
 *Submitted for verification at Etherscan.io on 2023-09-15
*/

// SPDX-License-Identifier: MIT

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

// File @openzeppelin/contracts/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
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

// File @openzeppelin/contracts/security/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File contracts/Staking.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Staking is Ownable, ReentrancyGuard {
    IERC20 public token;
    uint256 public lockDuration = 1 days;
    uint256 public totalETHDistributed;
    uint256 public amountETHToRelease = 5 ether;
    uint256 public releaseInterval = 1 days;
    uint256 public lastRelease;
    uint256 public totalStaked;
    uint256 public totalRewards;

    bool public stakingOpen;
    bool public distributedOpened;

    uint256 public magnifiedPerShare;
    uint256 internal constant magnitude = 2 ** 128;

    mapping(address => uint256) public staked;
    mapping(address => uint256) public claimed;
    mapping(address => uint256) public lastActive;
    mapping(address => uint256) public magnifiedCorrections;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event Distributed(uint256 amount);
    event RealeaseIntervalChanged(uint256 amount);
    event AmountETHToRealeaseChanged(uint256 amount);
    event StakingOpened();
    event Compound(
        address indexed user,
        uint256 amountETH,
        uint256 amountToken
    );

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setRealeaseInterval(uint256 _realeaseInterval) external onlyOwner {
        releaseInterval = _realeaseInterval;
        emit RealeaseIntervalChanged(_realeaseInterval);
    }

    function openStaking() external onlyOwner {
        require(!stakingOpen, "staking already open");
        stakingOpen = true;
    }

    function setAmountETHToRealease(
        uint256 _amountETHToRealease
    ) external onlyOwner {
        amountETHToRelease = _amountETHToRealease;
        emit AmountETHToRealeaseChanged(_amountETHToRealease);
    }

    function claimableOf(address _owner) public view returns (uint256) {
        return accumulativeOf(_owner) - claimed[_owner];
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        require(stakingOpen, "staking not open");
        token.transferFrom(msg.sender, address(this), _amount);
        this.claim(msg.sender);
        unchecked {
            staked[msg.sender] += _amount;
            totalStaked += _amount;
            magnifiedCorrections[msg.sender] -= (magnifiedPerShare * _amount);
        }
        emit Staked(msg.sender, _amount);
    }

    function withdraw() external {
        require(staked[msg.sender] > 0, "Cannot withdraw 0");
        require(
            lastActive[msg.sender] + lockDuration <= block.timestamp,
            "Cannot withdraw before lock duration"
        );
        this.claim(msg.sender);
        unchecked {
            staked[msg.sender] = 0;
            totalStaked -= staked[msg.sender];
            magnifiedCorrections[msg.sender] += (magnifiedPerShare *
                staked[msg.sender]);
        }
        token.transfer(msg.sender, staked[msg.sender]);
        emit Withdrawn(msg.sender, staked[msg.sender]);
    }

    function compound() external nonReentrant {
        uint256 claimable = claimableOf(msg.sender);
        IUniswapRouter router = IUniswapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        require(claimable > 0, "Nothing to compound");
        claimed[msg.sender] += claimable;
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);
        uint256 balanceBefore = token.balanceOf(address(this));
        router.swapExactETHForTokens{value: claimable}(
            0,
            path,
            address(this),
            block.timestamp + 360
        );
        uint256 amountToken = token.balanceOf(address(this)) - balanceBefore;
        unchecked {
            staked[msg.sender] += amountToken;
            totalStaked += amountToken;
            magnifiedCorrections[msg.sender] -= (magnifiedPerShare *
                amountToken);
        }
        emit Compound(msg.sender, claimable, amountToken);
    }

    function claim(address _user) external nonReentrant {
        require(
            msg.sender == _user || msg.sender == address(this),
            "not allowed"
        );
        uint256 claimable = claimableOf(_user);
        lastActive[_user] = block.timestamp;
        if (claimable > 0) {
            claimed[_user] += claimable;
            payable(_user).transfer(claimable);
        }
        emit Claimed(_user, claimable);
    }

    function accumulativeOf(address _owner) public view returns (uint256) {
        unchecked {
            return
                ((magnifiedPerShare * staked[_owner]) +
                    magnifiedCorrections[_owner]) / magnitude;
        }
    }

    function startDistribution() external onlyOwner {
        require(!distributedOpened, "distribution already started");
        require(stakingOpen, "staking not open");
        require(address(this).balance >= amountETHToRelease, "not enough eth");
        require(totalStaked > 0, "no stakers");
        distributedOpened = true;
        lastRelease = block.timestamp;
        unchecked {
            totalETHDistributed += amountETHToRelease;
            magnifiedPerShare =
                magnifiedPerShare +
                ((amountETHToRelease * magnitude) / totalStaked);
        }
    }

    receive() external payable {
        uint256 balance = address(this).balance;
        totalRewards += msg.value;
        if (
            balance - totalETHDistributed >= amountETHToRelease &&
            lastRelease + releaseInterval <= block.timestamp &&
            totalStaked > 0 &&
            distributedOpened
        ) {
            unchecked {
                totalETHDistributed += amountETHToRelease;
                magnifiedPerShare =
                    magnifiedPerShare +
                    ((amountETHToRelease * magnitude) / totalStaked);
            }
            lastRelease = block.timestamp;
        }
        emit Distributed(amountETHToRelease);
    }
}