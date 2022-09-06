/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface LegacyToken {
    function transfer(address, uint) external;
}

contract ConstantReturnStaking is Ownable {
    using Address for address;
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address indexed holder, uint amount);
    event ReferralFeeTransferred(address indexed referrer, uint amount);
    event Reinvest(address indexed holder, uint amount);

    event EmergencyDeclared(address owner);
    event StakingFeeChanged(uint fee);
    event UnstakingFeeChanged(uint fee);
    event RewardRateChanged(uint rewardRate);
    
    // ============================= CONTRACT VARIABLES ==============================
    
    // stake token contract address
    address public constant TRUSTED_TOKEN_ADDRESS = 0xBD100d061E120b2c67A24453CF6368E63f1Be056;
    
    // earnings reward rate
    uint public REWARD_RATE_X_100 = 1500;
    uint public constant REWARD_INTERVAL = 365 days;
    
    // staking fee
    uint public STAKING_FEE_RATE_X_100 = 100;
    
    // unstaking fee 
    uint public UNSTAKING_FEE_RATE_X_100 = 0;
    
    // this % of earned rewards go to referrer
    uint public constant REFERRAL_FEE_RATE_X_100 = 500;
    
    // unstaking possible after 72 hours
    uint public LOCKUP_TIME = 5 minutes;
    
    uint public constant ADMIN_CAN_CLAIM_AFTER = 395 days;

    uint public constant EMERGENCY_WAIT_TIME = 3 days;
    
    // ========================= END CONTRACT VARIABLES ==============================
    
    uint public totalClaimedRewards = 0;
    uint public totalClaimedReferralFee = 0;
    
    uint public immutable contractStartTime;

    uint public adminClaimableTime;

    bool public isEmergency = false;
    
    // Contracts are not allowed to deposit, claim or withdraw
    modifier noContractsAllowed() {
        require(!(address(msg.sender).isContract()) && tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }

    modifier notDuringEmergency() {
        require(!isEmergency, "Cannot execute during emergency!");
        _;
    }
    
    function declareEmergency() external onlyOwner notDuringEmergency {
        isEmergency = true;
        adminClaimableTime = now.add(EMERGENCY_WAIT_TIME);
        LOCKUP_TIME = 0;
        
        emit EmergencyDeclared(owner);
    }
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    
    mapping (address => uint) public rewardsPendingClaim;
    
    mapping (address => address) public referrals;
    mapping (address => uint) public totalReferralFeeEarned;
    
    mapping (address => EnumerableSet.AddressSet) private activeReferredAddressesOfUser;
    mapping (address => EnumerableSet.AddressSet) private totalReferredAddressesOfUser;
    
    constructor() public {
        contractStartTime = now;
        adminClaimableTime = now.add(ADMIN_CAN_CLAIM_AFTER);
    }
    
    function updateAccount(address account) private {
        uint pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            uint referralFee = pendingDivs.mul(REFERRAL_FEE_RATE_X_100).div(100e2);
            uint pendingDivsAfterFee = pendingDivs.sub(referralFee);
            
            bool success = transferReferralFeeIfPossible(referrals[account], referralFee);
            
            uint amount = pendingDivs;
            if (success) {
                amount = pendingDivsAfterFee;
            }
            
            
            rewardsPendingClaim[account] = rewardsPendingClaim[account].add(amount);
            totalEarnedTokens[account] = totalEarnedTokens[account].add(amount);
            
            totalClaimedRewards = totalClaimedRewards.add(amount);
            
        }
        lastClaimedTime[account] = now;
    }
    
    function transferReferralFeeIfPossible(address account, uint amount) private returns (bool) {
        if (account != address(0) && amount > 0) {
            totalReferralFeeEarned[account] = totalReferralFeeEarned[account].add(amount);
            require(Token(TRUSTED_TOKEN_ADDRESS).transfer(account, amount), "Could not transfer referral fee!");
            totalClaimedReferralFee = totalClaimedReferralFee.add(amount);
            emit ReferralFeeTransferred(account, amount);
            return true;
        }
        return false;
    }
    
    function getPendingDivs(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;
        
        uint timeDiff;
        uint stakingEndTime = contractStartTime.add(REWARD_INTERVAL);
        uint _now = now;
        if (_now > stakingEndTime) {
            _now = stakingEndTime;
        }
        
        if (lastClaimedTime[_holder] >= _now) {
            timeDiff = 0;
        } else {
            timeDiff = _now.sub(lastClaimedTime[_holder]);
        }

        uint stakedAmount = depositedTokens[_holder];
        
        uint pendingDivs = stakedAmount
                            .mul(REWARD_RATE_X_100)
                            .mul(timeDiff)
                            .div(REWARD_INTERVAL)
                            .div(1e4);
            
        return pendingDivs;
    }
    
    function getTotalPendingDivs(address _holder) external view returns (uint) {
        uint pending = getPendingDivs(_holder);
        uint awaitingClaim = rewardsPendingClaim[_holder];
        return pending.add(awaitingClaim);
    }
    
    function getNumberOfHolders() external view returns (uint) {
        return holders.length();
    }
    
    function getNumberOfReferredStakers(address referrer) external view returns (uint _activeStakers, uint _totalStakers) {
        _activeStakers = activeReferredAddressesOfUser[referrer].length();
        _totalStakers = totalReferredAddressesOfUser[referrer].length();
    }
    
    function getReferredStaker(address account, uint i) external view returns (address _staker, uint _totalEarned) {
        _staker = totalReferredAddressesOfUser[account].at(i);
        _totalEarned = totalEarnedTokens[_staker];
    }
    function getActiveReferredStaker(address account, uint i) external view returns (address _staker, uint _totalEarned) {
        _staker = activeReferredAddressesOfUser[account].at(i);
        _totalEarned = totalEarnedTokens[_staker];
    }
    
    
    function stake(uint amountToStake, address referrer) external noContractsAllowed notDuringEmergency {
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(Token(TRUSTED_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");
        
        updateAccount(msg.sender);
        
        uint fee = amountToStake.mul(STAKING_FEE_RATE_X_100).div(1e4);
        uint amountAfterFee = amountToStake.sub(fee);
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(owner, fee), "Could not transfer deposit fee.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountAfterFee);
        
        holders.add(msg.sender);
        
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = referrer;
        }
        
        totalReferredAddressesOfUser[referrals[msg.sender]].add(msg.sender);
        activeReferredAddressesOfUser[referrals[msg.sender]].add(msg.sender);
        
        stakingTime[msg.sender] = now;
    }
    
    function unstake(uint amountToWithdraw) external noContractsAllowed {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        
        require(now.sub(stakingTime[msg.sender]) > LOCKUP_TIME, "You recently staked, please wait before withdrawing.");
        
        updateAccount(msg.sender);
        
        uint fee = amountToWithdraw.mul(UNSTAKING_FEE_RATE_X_100).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(owner, fee), "Could not transfer withdraw fee.");
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
            activeReferredAddressesOfUser[referrals[msg.sender]].remove(msg.sender);
        }
    }
    
    // emergency unstake without caring about pending earnings
    // pending earnings will be lost / set to 0 if used emergency unstake
    function emergencyUnstake(uint amountToWithdraw) external noContractsAllowed {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        
        require(now.sub(stakingTime[msg.sender]) > LOCKUP_TIME, "You recently staked, please wait before withdrawing.");
        
        // set pending earnings to 0 here
        lastClaimedTime[msg.sender] = now;
        
        uint fee = amountToWithdraw.mul(UNSTAKING_FEE_RATE_X_100).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(owner, fee), "Could not transfer withdraw fee.");
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claim() external noContractsAllowed notDuringEmergency {
        updateAccount(msg.sender);
        uint amount = rewardsPendingClaim[msg.sender];
        if (amount > 0) {
            rewardsPendingClaim[msg.sender] = 0;
            require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, amount), "Could not transfer earned tokens.");  
            emit RewardsTransferred(msg.sender, amount);
        }
    }
    
    function reInvest() external noContractsAllowed notDuringEmergency {
        updateAccount(msg.sender);
        uint amount = rewardsPendingClaim[msg.sender];
        if (amount > 0) {
            rewardsPendingClaim[msg.sender] = 0;
            
            // re-invest here
            depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amount);
            
            // stakingTime[msg.sender] = now;
            emit Reinvest(msg.sender, amount);
        }
    }
    
    function getStakersList(uint startIndex, uint endIndex) 
        public 
        view 
        returns (address[] memory stakers, 
            uint[] memory stakingTimestamps, 
            uint[] memory lastClaimedTimeStamps,
            uint[] memory stakedTokens) {
        require (startIndex < endIndex);
        
        uint length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint[] memory _stakingTimestamps = new uint[](length);
        uint[] memory _lastClaimedTimeStamps = new uint[](length);
        uint[] memory _stakedTokens = new uint[](length);
        
        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders.at(i);
            uint listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = stakingTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }
        
        return (_stakers, _stakingTimestamps, _lastClaimedTimeStamps, _stakedTokens);
    }

    // function to allow admin to set new Staking Fee
    function setRewardRateX100(uint newRewardRate) public onlyOwner {
        REWARD_RATE_X_100 = newRewardRate;
        emit RewardRateChanged(REWARD_RATE_X_100);
    }

    // function to allow admin to set new Staking Fee
    function setStakingFeeRateX100(uint newStakingFeeRateX100) public onlyOwner {
        require(newStakingFeeRateX100 < 100e2, "Invalid fee!");
        STAKING_FEE_RATE_X_100 = newStakingFeeRateX100;
        emit StakingFeeChanged(STAKING_FEE_RATE_X_100);
    }

    // function to allow admin to set new Unstaking Fee
    function setUnstakingFeeRateX100(uint newUnstakingFeeRateX100) public onlyOwner {
        require(newUnstakingFeeRateX100 < 100e2, "Invalid fee!");
        UNSTAKING_FEE_RATE_X_100 = newUnstakingFeeRateX100;
        emit UnstakingFeeChanged(UNSTAKING_FEE_RATE_X_100);
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferAnyERC20Token(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require (now > adminClaimableTime, "Contract not expired yet!");
        require (Token(tokenAddress).transfer(recipient, amount), "Transfer failed!");
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferAnyLegacyERC20Token(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require (now > adminClaimableTime, "Contract not expired yet!");
        LegacyToken(tokenAddress).transfer(recipient, amount);
    }
}