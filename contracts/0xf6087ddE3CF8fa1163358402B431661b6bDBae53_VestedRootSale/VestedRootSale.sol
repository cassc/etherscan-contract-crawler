/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

pragma solidity ^0.8.0;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

interface IROOT is IERC20{
    function mint(address to, uint256 amount) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

contract VestedRootSale is Ownable{

    uint256 public pricePerToken;
    uint256 public purchaseCap;
    uint256 public purchased;

    uint256 public tgeTime;
    uint256 public cliffDuration;
    uint256 public vestingDuration;

    uint16 public upfrontBP;

    bool public saleActive;

    mapping (address => uint256) public userPurchased;
    mapping (address => uint256) public claimed;

    IROOT public root;

    event Purchase(address indexed user, uint256 amount);

    constructor(
        uint256 _pricePerToken,
        uint256 _purchaseCap,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        uint16 _upfrontBP
    ) {
        pricePerToken = _pricePerToken;
        purchaseCap = _purchaseCap;
        cliffDuration = _cliffDuration;
        vestingDuration = _vestingDuration;
        upfrontBP = _upfrontBP;
    }

    function purchase() public payable {
        require(saleActive, "sale is not active");
        uint256 amount = msg.value * 1e18 / pricePerToken;
        require(purchased + amount <= purchaseCap, "purchase cap reached");
        purchased += amount;
        userPurchased[msg.sender] += amount;
        emit Purchase(msg.sender, amount);
    }

    function claim() public {
        require(tgeTime > 0, "tge time not set");
        require(block.timestamp >= tgeTime, "tge has not passed");
        uint256 amount = claimable(msg.sender);
        require(amount > 0, "nothing to claim");
        claimed[msg.sender] += amount;
        root.mint(msg.sender, amount);
    }

    function claimable(address user) public view returns (uint256) {
        if (tgeTime == 0) return 0;
        if (userPurchased[user] == 0) return 0;
        if (claimed[user] >= userPurchased[user]) return 0;

        uint256 cliffTime = tgeTime + cliffDuration;
        if (block.timestamp < cliffTime) return 0;

        uint256 endVesting = cliffTime + vestingDuration;
        if (block.timestamp >= endVesting) return userPurchased[user] - claimed[user];

        uint256 vested = userPurchased[user] * (10000 - upfrontBP) * (block.timestamp - cliffTime) / vestingDuration / 10000;
        uint256 upfront = userPurchased[user] * upfrontBP / 10000;

        return vested + upfront - claimed[user];

    }

    function setTgeTime(uint256 _tgeTime) public onlyOwner {
        require(saleActive == false, "sale already active");
        require(tgeTime == 0, "tge time already set");
        tgeTime = _tgeTime;
    }

    function setRoot(address _root) public onlyOwner {
        root = IROOT(_root);
    }

    function setSaleActive(bool _saleActive) public onlyOwner {
        require(tgeTime == 0, "tge time already set");
        saleActive = _saleActive;
    }

    function withdrawETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}