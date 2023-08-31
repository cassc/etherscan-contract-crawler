/**
 *Submitted for verification at Etherscan.io on 2023-08-26
*/

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

pragma solidity ^0.8.0;



contract StakingContract is Ownable {

    IERC20 public token; // The ERC20 token being staked
    
    uint256 public apy;
    uint256 public rewardCycleDays;
    uint256 public totalstaked;
    uint256 public lockPeriod;
    
    struct User {
        uint256 stakedAmount;
        uint256 accumulutedreward;
        uint256 lastClaimTimestamp;
        uint256 startTime;
    }
    
    mapping(address => User) public users;

    address[] public totalusers;

    mapping(address => bool) public firstStake;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event APYUpdated(uint256 newAPY);
    event RewardCycleDaysUpdated(uint256 newCycleDays);
    
    constructor(address _tokenAddress, uint256 _initialAPY, uint256 _initialCycleDays,uint256 _lockPeriod) {
        token = IERC20(_tokenAddress);
        apy = _initialAPY;
        rewardCycleDays = _initialCycleDays;
        lockPeriod=_lockPeriod;
    }
    
    function adjustAPY(uint256 _newAPY) external onlyOwner {
        apy = _newAPY;
        emit APYUpdated(_newAPY);
    }
    
    function adjustRewardCycleDays(uint256 _newCycleDays) external onlyOwner {
        rewardCycleDays = _newCycleDays;
        emit RewardCycleDaysUpdated(_newCycleDays);
    }

    function adjustLockPeriod(uint256 _lockPeriod) public{
        lockPeriod=_lockPeriod;
    }
    
    function stake(uint256 _amount) external {
        if(firstStake[msg.sender] == false){
            totalusers.push(msg.sender);
            firstStake[msg.sender]=true;
            users[msg.sender].lastClaimTimestamp=block.timestamp;

        }
        require(_amount > 0, "Amount must be greater than 0");
        
        token.transferFrom(msg.sender, address(this), _amount);
        totalstaked+=_amount;
        users[msg.sender].startTime=block.timestamp;
        users[msg.sender].stakedAmount += _amount;
        emit Staked(msg.sender, _amount);
    }
    
    function unstake(uint256 _amount) external {
        require(block.timestamp >= users[msg.sender].startTime+lockPeriod*86400,"Token Lock Period not finished");
        require(users[msg.sender].stakedAmount >= _amount, "Insufficient staked amount");
        uint256 reward = (users[msg.sender].stakedAmount * apy * rewardCycleDays) / (365 * 100);
        users[msg.sender].accumulutedreward+=reward;
        users[msg.sender].startTime=0;
        users[msg.sender].stakedAmount -= _amount;
        token.transfer(msg.sender, _amount); // Transfer tokens back to user
        totalstaked-=_amount;
        emit Unstaked(msg.sender, _amount);
    }
    
    function claimRewards() external {
        require(users[msg.sender].lastClaimTimestamp + (rewardCycleDays * 1 days) <= block.timestamp, "Reward claim cycle not completed yet");
        
        uint256 reward = (users[msg.sender].stakedAmount * apy * rewardCycleDays) / (365 * 100);
        
        token.transfer(msg.sender, reward+users[msg.sender].accumulutedreward); // Transfer rewards to user
        users[msg.sender].accumulutedreward=0;
        users[msg.sender].lastClaimTimestamp = block.timestamp;
        emit RewardClaimed(msg.sender, reward);
    }

   
    
    // Read-only methods
    
    function getStakedAmount(address _user) public view returns (uint256) {
        return users[_user].stakedAmount;
    }
    
    function getTimeRemainingForUnstake(address _user) public view returns (uint256) {
        if (users[_user].stakedAmount == 0) {
            return 0; // No staked amount, no time remaining
        }
        uint256 nextUnstakeTimestamp = users[_user].lastClaimTimestamp + (rewardCycleDays * 1 days);
        if (nextUnstakeTimestamp <= block.timestamp) {
            return 0; // Claim cycle completed, no time remaining
        }
        return nextUnstakeTimestamp - block.timestamp;
    }

    function getReward(address _address) public view returns(uint256){
        uint256 reward = (users[_address].stakedAmount * apy * rewardCycleDays) / (365 * 100);
        return (reward+users[msg.sender].accumulutedreward);   
    }

    function getTotalUsers() public view returns(uint256){
         return totalusers.length;
    }

    function getTotalStaked() public view returns(uint256){
         return totalstaked;
    }

    function getAPY() public view returns(uint256){
         return apy;
    }

    function getRewardCycleDays() public view returns(uint256){
         return rewardCycleDays;
    }


}