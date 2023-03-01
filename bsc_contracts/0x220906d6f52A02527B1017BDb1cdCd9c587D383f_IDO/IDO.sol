/**
 *Submitted for verification at BscScan.com on 2023-02-28
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRegister {
    event Regist(address player, address inviter);

    function addDefaultInviter(address addr) external returns (bool);

    function regist(address _inviter) external returns (bool);

    function registed(address _player) external view returns (bool);

    function myInviter(address _player) external view returns (address);
}

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
    function allowance(address owner, address spender)
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

pragma solidity ^0.8.0;

contract IDO is Ownable {
    IERC20 public tokenIn;
    IERC20 public tokenOut;
    IRegister public register;
    uint256 public tokenInAmount;
    uint256 public tokenOutAmount;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalSupply;
    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 public inviter1 = 7;
    uint256 public inviter2 = 3;
    uint256 public currentSubscribedAmount;
    bool public withdrawEnable;
    uint256 public withdrawStartTime;
    uint256 public withdrawReleaseCycle = 30 days;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => bool) public subscribed;

    event Subscribe(address subscriber);
    event Withdraw(address subscriber, uint256 amount);

    constructor(
        address tokenIn_,
        uint256 tokenInAmount_,
        uint256 tokenOutAmount_,
        uint256 startTime_,
        uint256 endTime_,
        address register_,
        uint256 totalSupply_
    ) {
        tokenIn = IERC20(tokenIn_);
        tokenInAmount = tokenInAmount_;
        tokenOutAmount = tokenOutAmount_;
        startTime = startTime_;
        endTime = endTime_;
        register = IRegister(register_);
        totalSupply = totalSupply_;
    }

    function setTokenOut(address token_) public onlyOwner returns (bool) {
        tokenOut = IERC20(token_);
        return true;
    }

    function subscribe() public returns (bool) {
        address subscriber = msg.sender;
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "IDO: Not the time"
        );
        require(register.registed(subscriber), "IDO: Not regist");
        require(!subscribed[subscriber], "IDO: Subscribed");
        require(
            totalSupply - currentSubscribedAmount >= tokenOutAmount,
            "IDO: Not enough token"
        );
        address inviter = register.myInviter(subscriber);
        if (inviter == address(0)) {
            //whitelist
            inviter = address(this);
        }
        subscribed[subscriber] = true;
        currentSubscribedAmount += tokenOutAmount;
        balances[subscriber] = tokenOutAmount;
        require(
            tokenIn.transferFrom(
                subscriber,
                address(this),
                (tokenInAmount * 90) / 100
            ),
            "IDO: Transfer token in error"
        );
        require(
            tokenIn.transferFrom(
                subscriber,
                inviter,
                (tokenInAmount * 7) / 100
            ),
            "IDO: Transfer token in to inviterOne error"
        );

        address inviterTwo = register.myInviter(inviter);
        if (inviterTwo == address(0)) {
            inviterTwo = address(this);
        }
        require(
            tokenIn.transferFrom(
                subscriber,
                inviterTwo,
                (tokenInAmount * 3) / 100
            ),
            "IDO: Transfer token in to inviterTwo error"
        );
        // require(
        //     tokenOut.transfer(subscriber, tokenOutAmount / 2),
        //     "IDO: Transfer token out error"
        // );
        emit Subscribe(subscriber);
        return true;
    }

    function withdraw() public returns (bool) {
        address subscriber = msg.sender;
        require(
            withdrawEnable &&
                withdrawStartTime != 0 &&
                block.timestamp >= withdrawStartTime,
            "IDO: Not the time"
        );
        require(
            balances[subscriber] > 0,
            "IDO: There is no withdrawable balance"
        );
        uint256 amount = withdrawableAmount(subscriber);
        lastWithdrawTime[subscriber] = block.timestamp;
        balances[subscriber] -= amount;
        require(
            tokenOut.transfer(subscriber, amount),
            "IDO: Transfer token out error"
        );
        emit Withdraw(subscriber, amount);
        return true;
    }

    function withdrawableAmount(address subscriber)
        public
        view
        returns (uint256)
    {
        uint256 amount;
        uint256 subscriberLastWithdrawTime = lastWithdrawTime[subscriber];
        if (subscriberLastWithdrawTime == 0) {
            amount = tokenOutAmount / 2; //the first time withdraw release half
            subscriberLastWithdrawTime = withdrawStartTime;
        }
        uint256 releaseAmountSecond = tokenOutAmount / 2 / withdrawReleaseCycle;
        uint256 linearReleaseAmount = (block.timestamp -
            subscriberLastWithdrawTime) * releaseAmountSecond;
        amount += linearReleaseAmount;
        if (amount > balances[subscriber]) {
            amount = balances[subscriber];
        }
        return amount;
    }

    function EnabelWithdraw() public onlyOwner returns (bool) {
        withdrawEnable = true;
        return true;
    }

    function SetWithdrawStartTime(uint256 time)
        public
        onlyOwner
        returns (bool)
    {
        withdrawStartTime = time;
        return true;
    }

    function burn() public onlyOwner returns (bool) {
        require(block.timestamp > endTime, "IDO: Not the time");
        return
            IERC20(tokenOut).transfer(
                _destroyAddress,
                totalSupply - currentSubscribedAmount
            );
    }

    function withdrawERC20(address tokenAdress, address to)
        public
        onlyOwner
        returns (bool)
    {
        IERC20 token = IERC20(tokenAdress);
        return token.transfer(to, token.balanceOf(address(this)));
    }

    function getIDOInfo()
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            address(tokenIn),
            address(tokenOut),
            tokenInAmount,
            tokenOutAmount,
            startTime,
            endTime,
            totalSupply
        );
    }

    function getBalances(address addr) public view returns (uint256) {
        return balances[addr];
    }

    function getLastWithdrawTime(address addr) public view returns (uint256) {
        return lastWithdrawTime[addr];
    }

    function isSubscribed(address addr) public view returns (bool) {
        return subscribed[addr];
    }
}