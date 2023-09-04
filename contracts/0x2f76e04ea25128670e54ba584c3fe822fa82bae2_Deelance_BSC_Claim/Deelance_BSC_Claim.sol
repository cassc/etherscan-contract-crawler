/**
 *Submitted for verification at Etherscan.io on 2023-07-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

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

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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


contract Deelance_BSC_Claim is Ownable {
    IERC20 public assignedToken;
    
    // mapping of user addresses to their token balances
    mapping(address => uint256) public balances;
    
    bool public paused = false;

    constructor(IERC20 _token, address _owner) Ownable(_owner) {
        assignedToken = _token;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // owner can pause/unpause the contract
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    // only callable by owner, used to add users to the contract and assign them token balances
    function addUsers(address[] calldata _users, uint256[] calldata _amounts) external onlyOwner  {
        require(_users.length == _amounts.length, "Users and amounts arrays must have the same length");

        uint256 totalAmount = 0;
        for(uint256 i = 0; i < _users.length; i++) {
            balances[_users[i]] += _amounts[i];
            totalAmount += _amounts[i];
        }
        
        require(assignedToken.transferFrom(msg.sender, address(this), totalAmount), "Token transfer failed");
    }

    // users can claim their tokens by calling this function
    function claimTokens() external whenNotPaused {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No tokens to claim");
        require(assignedToken.balanceOf(address(this)) >= amount, "Not enough tokens in the contract");
        
        // update balance before transfer to prevent reentrancy attacks
        balances[msg.sender] = 0;
        
        require(assignedToken.transfer(msg.sender, amount), "Token transfer failed");
    }
    
    // owner can withdraw any unclaimed tokens of the assigned type
    function withdraw() external onlyOwner {
        uint256 contractBalance = assignedToken.balanceOf(address(this));
        require(contractBalance > 0, "No tokens to withdraw");
        
        require(assignedToken.transfer(owner(), contractBalance), "Token transfer failed");
    }

    // only callable by owner, used to remove a user from the contract and zero their balance
    function removeUser(address _user) external onlyOwner {
        require(balances[_user] > 0, "User does not exist or balance is already zero");
        balances[_user] = 0;
    }

    // only callable by owner, used to modify the token amount of a user
    function modifyUserAmount(address _user, uint256 _newAmount) external onlyOwner {
        require(balances[_user] > 0, "User does not exist");
        balances[_user] = _newAmount;
    }

    // owner can withdraw any type of ERC20 tokens
    function withdrawOtherTokens(IERC20 _token) external onlyOwner {
        uint256 contractBalance = _token.balanceOf(address(this));
        require(contractBalance > 0, "No tokens to withdraw");

        require(_token.transfer(owner(), contractBalance), "Token transfer failed");
    }
}