/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// File: contracts/IERC900.sol



pragma solidity ^0.8.0;

interface IERC900 {

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount, bytes memory data) external;
    function stakeFor(address user, uint256 amount, bytes memory data) external;
    function unstake(uint256 amount, bytes memory data) external;
    function totalStakedFor(address addr) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function token() external view returns (address);
    function supportsHistory() external pure returns (bool);

    // optional
    // function lastStakedFor(address addr) public view returns (uint256);
    // function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
    // function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/SpiExtStaking.sol



pragma solidity ^0.8.0;




contract SpiExtStaking is IERC900 {
    // Token used for staking
    IERC20 stakingToken;

    // The default duration of stake lock-in (in seconds)
    uint256 public defaultLockInDuration;

    // To save on gas, rather than create a separate mapping for totalStakedFor & personalStakes,
    //  both data structures are stored in a single mapping for a given addresses.
    //
    // It's possible to have a non-existing personalStakes, but have tokens in totalStakedFor
    //  if other users are staking on behalf of a given address.
    mapping(address => StakeContract) public stakeHolders;

    Income[] public incomes;

    uint256 public totalStaked;

    // Struct for personal stakes (i.e., stakes made by this address)
    // unlockedTimestamp - when the stake unlocks (in seconds since Unix epoch)
    // actualAmount - the amount of tokens in the stake
    // stakedFor - the address the stake was staked for
    struct Stake {
        uint256 unlockedTimestamp;
        uint256 actualAmount;
        address stakedFor;
    }

    // Struct for all stake metadata at a particular address
    // totalStakedFor - the number of tokens staked for this address
    // personalStakeIndex - the index in the personalStakes array.
    // personalStakes - append only array of stakes made by this address
    // exists - whether or not there are stakes that involve this address
    struct StakeContract {
        uint256 totalStakedFor;

        uint256 personalStakeIndex;

        Stake[] personalStakes;

        uint256 dividends;

        uint256 paid;

        uint incomeIndex;

        bool exists;
    }

    struct Income {
        uint256 amount;
        uint256 remainingAmount;
        uint256 totalStaked;
    }

    /**
      Events
    */
    event IncomeAdded(address indexed user, uint256 amount);
    event DividendsClaimed(address indexed user, uint256 amount);
    /**
     * @dev Modifier that checks that this contract can transfer tokens from the
       *  balance in the stakingToken contract for the given address.
       * @dev This modifier also transfers the tokens.
       * @param _address address to transfer tokens from
       * @param _amount uint256 the number of tokens
       */
    modifier canStake(address _address, uint256 _amount) {
        require(stakingToken.transferFrom(_address, address(this), _amount), "Stake required");
        _;
    }

    /**
     * @dev Constructor function
       * @param _stakingToken ERC20 The address of the token contract used for staking
       */
    constructor(IERC20 _stakingToken, uint256 _defaultLockInDuration) {
      require(address(_stakingToken) != address(0), "Staking token address can't be set to 0");
      require(_defaultLockInDuration > 0, "Staking duration should be more than 0");
      stakingToken = _stakingToken;
      defaultLockInDuration = _defaultLockInDuration;
    }

    /**
     * @dev Returns the timestamps for when active personal stakes for an address will unlock
       * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
       * @param _address address that created the stakes
       * @return uint256[] array of timestamps
       */
    function getPersonalStakeUnlockedTimestamps(address _address) external view returns (uint256[] memory) {
        uint256[] memory timestamps;
        (timestamps,,) = getPersonalStakes(_address);

        return timestamps;
    }

    /**
     * @dev Returns the stake actualAmount for active personal stakes for an address
       * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
       * @param _address address that created the stakes
       * @return uint256[] array of actualAmounts
       */
    function getPersonalStakeActualAmounts(address _address) external view returns (uint256[] memory) {
        uint256[] memory actualAmounts;
        (, actualAmounts,) = getPersonalStakes(_address);

        return actualAmounts;
    }

    /**
     * @dev Returns the addresses that each personal stake was created for by an address
       * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
       * @param _address address that created the stakes
       * @return address[] array of amounts
       */
    function getPersonalStakeForAddresses(address _address) external view returns (address[] memory) {
        address[] memory stakedFor;
        (,, stakedFor) = getPersonalStakes(_address);

        return stakedFor;
    }

    /**
     * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the user
       * @notice MUST trigger Staked event
       * @param _amount uint256 the amount of tokens to stake
       * @param _data bytes optional data to include in the Stake event
       */
    function stake(uint256 _amount, bytes memory _data) public override {
        createStake(msg.sender, _amount, defaultLockInDuration, _data);
    }

    /**
     * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
       * @notice MUST trigger Staked event
       * @param _user address the address the tokens are staked for
       * @param _amount uint256 the amount of tokens to stake
       * @param _data bytes optional data to include in the Stake event
       */
    function stakeFor(address _user, uint256 _amount, bytes memory _data) public override {
        createStake(_user, _amount, defaultLockInDuration,_data);
    }

    /**
     * @notice Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the user, if unstaking is currently not possible the function MUST revert
       * @notice MUST trigger Unstaked event
       * @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
       * @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
       *  transferred back to their account, and their personalStakeIndex will increment to the next active stake.
       * @param _amount uint256 the amount of tokens to unstake
       * @param _data bytes optional data to include in the Unstake event
       */
    function unstake(uint256 _amount, bytes memory _data) public override {
        withdrawStake(_amount,_data);
    }

    /**
     * @notice Returns the current total of tokens staked for an address
       * @param _address address The address to query
       * @return uint256 The number of tokens staked for the given address
       */
    function totalStakedFor(address _address) public override view returns (uint256) {
        return stakeHolders[_address].totalStakedFor;
    }

    /**
     * @notice Address of the token being used by the staking interface
       * @return address The address of the ERC20 token used for staking
       */
    function token() public override view returns (address) {
        return address(stakingToken);
    }

    /**
     * @notice MUST return true if the optional history functions are implemented, otherwise false
       * @dev Since we don't implement the optional interface, this always returns false
       * @return bool Whether or not the optional history functions are implemented
       */
    function supportsHistory() public override pure returns (bool) {
        return false;
    }

    /**
     * @dev Helper function to get specific properties of all of the personal stakes created by an address
       * @param _address address The address to query
       * @return (uint256[], uint256[], address[])
       *  timestamps array, actualAmounts array, stakedFor array
       */
    function getPersonalStakes(address _address) view public returns (uint256[] memory, uint256[] memory, address[] memory)
    {
        StakeContract storage stakeContract = stakeHolders[_address];

        uint256 arraySize = stakeContract.personalStakes.length - stakeContract.personalStakeIndex;
        uint256[] memory unlockedTimestamps = new uint256[](arraySize);
        uint256[] memory actualAmounts = new uint256[](arraySize);
        address[] memory stakedFor = new address[](arraySize);

        for (uint i = stakeContract.personalStakeIndex; i < stakeContract.personalStakes.length; i++) {
            uint index = i - stakeContract.personalStakeIndex;
            unlockedTimestamps[index] = stakeContract.personalStakes[i].unlockedTimestamp;
            actualAmounts[index] = stakeContract.personalStakes[i].actualAmount;
            stakedFor[index] = stakeContract.personalStakes[i].stakedFor;
        }

        return (unlockedTimestamps, actualAmounts, stakedFor);
    }

    /**
     * @dev Helper function to create stakes for a given address
       * @param _address address The address the stake is being created for
       * @param _amount uint256 The number of tokens being staked
       * @param _lockInDuration uint256 The duration to lock the tokens for
       * @param _data bytes optional data to include in the Stake event
       */
    function createStake(address _address,uint256 _amount,uint256 _lockInDuration,bytes memory _data) internal canStake(msg.sender, _amount)
    {
        _createStake(_address, _amount, _lockInDuration, _data);
    }

    function stakeDividends(uint256 _amount, bytes memory _data) public {
        require(getUnpaidDividends(msg.sender) >= _amount, "Amount is greater than remaining dividends");
        _createStake(msg.sender, _amount, defaultLockInDuration, _data);
        stakeHolders[msg.sender].paid += _amount;
    }

    function _createStake(address _address,uint256 _amount,uint256 _lockInDuration,bytes memory _data) private {
        if (!stakeHolders[msg.sender].exists) {
            stakeHolders[msg.sender].exists = true;
        }

        updateDividends(_address);

        stakeHolders[_address].totalStakedFor += _amount;
        stakeHolders[_address].personalStakes.push(Stake(block.timestamp + _lockInDuration,_amount,_address));

        totalStaked +=_amount;

        emit Staked(_address,_amount,totalStakedFor(_address),_data);
    }

    /**
     * @dev Helper function to withdraw stakes for the msg.sender
       * @param _amount uint256 The amount to withdraw. MUST match the stake amount for the
       *  stake at personalStakeIndex.
       * @param _data bytes optional data to include in the Unstake event
       */
    function withdrawStake(uint256 _amount, bytes memory _data) internal {
        require(stakeHolders[msg.sender].exists, "The current address hasn't any stakes");

        Stake storage personalStake = stakeHolders[msg.sender].personalStakes[stakeHolders[msg.sender].personalStakeIndex];

        // Check that the current stake has unlocked & matches the unstake amount
        require(personalStake.unlockedTimestamp <= block.timestamp, "The current stake hasn't unlocked yet");

        require( personalStake.actualAmount == _amount,"The unstake amount does not match the current stake");

        // Transfer the staked tokens from this contract back to the sender
        // Notice that we are using transfer instead of transferFrom here, so
        //  no approval is needed beforehand.
        require(stakingToken.transfer(msg.sender, _amount),"Unable to withdraw stake");

        updateDividends(msg.sender);
        stakeHolders[personalStake.stakedFor].totalStakedFor = stakeHolders[personalStake.stakedFor].totalStakedFor - personalStake.actualAmount;

        personalStake.actualAmount = 0;
        stakeHolders[msg.sender].personalStakeIndex++;

        totalStaked -=_amount;

        emit Unstaked(personalStake.stakedFor,_amount,totalStakedFor(personalStake.stakedFor),_data);
    }

    function withdrawDividends(uint256 _amount) external {
        require(stakeHolders[msg.sender].exists, "The current address hasn't any stakes");
        require(_amount <= getUnpaidDividends(msg.sender), "Requested Amount exceed not paid erarings");
        stakeHolders[msg.sender].paid += _amount;
        require(stakingToken.transfer(msg.sender, _amount),"Unable to withdraw stake");
        emit DividendsClaimed(msg.sender, _amount);
    }

    function addIncome(uint256 _amount) public {
      require(_amount > 0, 'Amount should be greater than 0');
      require(stakingToken.transferFrom(msg.sender, address(this), _amount), 'Transfer of funds failed');
      incomes.push(Income(_amount,_amount, this.totalStaked()));
      emit IncomeAdded(msg.sender, _amount);
    }

    // View functions

    function getUnpaidDividends(address _address) view public returns(uint256) {
        uint256 dividends = getDividends(_address);
        if(dividends > 0 && dividends >= stakeHolders[_address].paid) {
          return dividends - stakeHolders[_address].paid;
        }
        return 0;
    }

    function totalPaid(address _address) external view returns (uint256) {
        return stakeHolders[_address].paid;
    }

    function getDividends(address _address) view public returns(uint256) {
        if(stakeHolders[_address].exists) {
          uint256 notAppliedDividendsAmountSum = calculateNotAppliedDividends(_address);
          return stakeHolders[_address].dividends + notAppliedDividendsAmountSum;
        }
        return 0;
    }

    //Private Functions

    function updateDividends(address _address) private {
      uint256 notAppliedDividendsAmountSum = calculateNotAppliedDividends(_address);
      stakeHolders[_address].dividends += notAppliedDividendsAmountSum;
      stakeHolders[_address].incomeIndex = incomes.length;
    }

    function calculateNotAppliedDividends(address _address) view private returns(uint256) {
        if(stakeHolders[_address].exists) {
            if(incomes.length > 0 && stakeHolders[_address].incomeIndex < incomes.length) {
                uint256 notAppliedDividendsAmount;
                for(uint i = stakeHolders[_address].incomeIndex; i < incomes.length; i++) {
                    notAppliedDividendsAmount += stakeHolders[_address].totalStakedFor * incomes[i].amount / incomes[i].totalStaked;
                }
                return notAppliedDividendsAmount;
            }
        }
        return 0;
    }

}