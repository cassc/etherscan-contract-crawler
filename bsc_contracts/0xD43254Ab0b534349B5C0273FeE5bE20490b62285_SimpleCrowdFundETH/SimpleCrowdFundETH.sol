/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: SimpleCrowdFundETH.sol

contract SimpleCrowdFundETH is Ownable {
    struct PledgeInfo {
        uint256 pledge;
        bool claimed;
    }

    uint256 public totalPledge;
    uint256 public tokensPerETH;
    IERC20 public rewardToken;

    bool public endSale;
    bool public success;
    uint256 public hardcap;

    mapping(address => PledgeInfo) public user;

    uint256 public minDeposit = 0.2 ether;
    uint256 public maxDeposit = 2 ether;

    event Pledge(address indexed user, uint256 amount);
    event ClaimToken(address indexed user, uint256 amount);
    event Claim(uint256 amount);
    event SaleEnded(bool status);

    constructor(uint256 hc) {
        hardcap = hc;
    }

    function pledge() external payable {
        require(!endSale, "Sale ended");
        uint256 amount = msg.value;
        require(amount >= minDeposit, "Not enough");
        PledgeInfo storage pi = user[msg.sender];
        pi.pledge += amount;
        require(pi.pledge <= maxDeposit, "Overboard");
        totalPledge += amount;
        require(totalPledge <= hardcap, "Reached!");
        if (totalPledge == hardcap) success = true;
        emit Pledge(msg.sender, amount);
    }

    function getRaiseFunds() external onlyOwner {
        require(success, "Not successful yet");
        uint256 current = address(this).balance;
        require(current > 0, "Not enough funds");
        (bool succ, ) = payable(owner()).call{value: current}("");
        require(succ, "Claim Failed");
        emit Claim(current);
    }

    function endTheSale() external onlyOwner {
        require(!endSale, "ONCE");
        endSale = true;
        emit SaleEnded(true);
    }

    function extractOtherFunds(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);

        balance = address(this).balance;
        if (balance > 0) {
            (bool succ, ) = payable(msg.sender).call{value: balance}("");
            require(succ, "err transferring funds");
        }
    }

    function claim() external {
        require(endSale && success && tokensPerETH > 0, "NOT YET");
        PledgeInfo storage pi = user[msg.sender];
        require(!pi.claimed && pi.pledge > 0, "DONE");
        pi.claimed = true;
        uint256 amountToClaim = tokensPerETH * pi.pledge;
        amountToClaim = amountToClaim / 1 ether;
        rewardToken.transfer(msg.sender, amountToClaim);
        emit ClaimToken(msg.sender, amountToClaim);
    }

    /// @notice set reward token info
    /// @param _token the new token address
    /// @param _tokensPerEth the amount of tokens to be given out to the user. This amount need to be in ether so it makes sense and mathwise wont fuck up anything.
    function setRewardToken(address _token, uint256 _tokensPerEth)
        external
        onlyOwner
    {
        rewardToken = IERC20(_token);
        tokensPerETH = _tokensPerEth;
    }

    function getRefund() external {
        require(endSale && !success, "Not Done");
        PledgeInfo storage pi = user[msg.sender];
        require(!pi.claimed && pi.pledge > 0, "Already claimed");
        pi.claimed = true;
        (bool succ, ) = payable(msg.sender).call{value: pi.pledge}("");
        require(succ, "Failed TX");
    }
}