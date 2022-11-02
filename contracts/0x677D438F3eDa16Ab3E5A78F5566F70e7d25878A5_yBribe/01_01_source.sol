pragma solidity 0.8.6;

// File: EnumerableSet.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: yBribe.sol

interface GaugeController {
    struct VotedSlope {
        uint slope;
        uint power;
        uint end;
    }
    
    struct Point {
        uint bias;
        uint slope;
    }
    
    function vote_user_slopes(address, address) external view returns (VotedSlope memory);
    function last_user_vote(address, address) external view returns (uint);
    function points_weight(address, uint) external view returns (Point memory);
    function checkpoint_gauge(address) external;
    function time_total() external view returns (uint);
    function gauge_types(address) external view returns (int128);
}

interface erc20 { 
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
}

contract yBribe {
    using EnumerableSet for EnumerableSet.AddressSet;

    event RewardAdded(address indexed briber, address indexed gauge, address indexed reward_token, uint amount, uint fee);
    event NewTokenReward(address indexed gauge, address indexed reward_token); // Specifies unique token added for first time to gauge
    event RewardClaimed(address indexed user, address indexed gauge, address indexed reward_token, uint amount);
    event Blacklisted(address indexed user);
    event RemovedFromBlacklist(address indexed user);
    event SetRewardRecipient(address indexed user, address recipient);
    event ClearRewardRecipient(address indexed user, address recipient);
    event ChangeOwner(address owner);
    event PeriodUpdated(address indexed gauge, uint indexed period, uint bias, uint blacklisted_bias);
    event FeeUpdated(uint fee);

    uint constant WEEK = 86400 * 7;
    uint constant PRECISION = 10**18;
    uint constant BPS = 10_000;
    GaugeController constant GAUGE = GaugeController(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
    
    mapping(address => mapping(address => uint)) public claims_per_gauge;
    mapping(address => mapping(address => uint)) public reward_per_gauge;
    
    mapping(address => mapping(address => uint)) public reward_per_token;
    mapping(address => mapping(address => uint)) public active_period;
    mapping(address => mapping(address => mapping(address => uint))) public last_user_claim;
    mapping(address => uint) public next_claim_time;
    
    mapping(address => address[]) public _rewards_per_gauge;
    mapping(address => address[]) public _gauges_per_reward;
    mapping(address => mapping(address => bool)) public _rewards_in_gauge;

    address public owner = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;
    address public fee_recipient = 0x93A62dA5a14C80f265DAbC077fCEE437B1a0Efde;
    address public pending_owner;
    uint public fee_percent = 100; // Expressed in BPS
    mapping(address => address) public reward_recipient;
    EnumerableSet.AddressSet private blacklist;
    
    function _add(address gauge, address reward) internal {
        if (!_rewards_in_gauge[gauge][reward]) {
            _rewards_per_gauge[gauge].push(reward);
            _gauges_per_reward[reward].push(gauge);
            _rewards_in_gauge[gauge][reward] = true;
            emit NewTokenReward(gauge, reward);
        }
    }
    
    function rewards_per_gauge(address gauge) external view returns (address[] memory) {
        return _rewards_per_gauge[gauge];
    }
    
    function gauges_per_reward(address reward) external view returns (address[] memory) {
        return _gauges_per_reward[reward];
    }
    
    /// @dev Required to sync each gauge/token pair to new week.
    /// @dev Can be triggered either by claiming or adding bribes to gauge/token pair.
    function _update_period(address gauge, address reward_token) internal returns (uint) {
        uint _period = active_period[gauge][reward_token];
        if (block.timestamp >= _period + WEEK) {
            _period = current_period();
            GAUGE.checkpoint_gauge(gauge);
            uint _bias = GAUGE.points_weight(gauge, _period).bias;
            uint blacklisted_bias = get_blacklisted_bias(gauge);
            _bias -= blacklisted_bias;
            emit PeriodUpdated(gauge, _period, _bias, blacklisted_bias);
            uint _amount = reward_per_gauge[gauge][reward_token] - claims_per_gauge[gauge][reward_token];
            if (_bias > 0){
                reward_per_token[gauge][reward_token] = _amount * PRECISION / _bias;
            }
            active_period[gauge][reward_token] = _period;
        }
        return _period;
    }
    
    function add_reward_amount(address gauge, address reward_token, uint amount) external returns (bool) {
        require(GAUGE.gauge_types(gauge) >= 0); // @dev: reverts on invalid gauge
        _safeTransferFrom(reward_token, msg.sender, address(this), amount);
        uint fee_take = fee_percent * amount / BPS;
        uint reward_amount = amount - fee_take;
        if (fee_take > 0){
            _safeTransfer(reward_token, fee_recipient, fee_take);
        }
        _update_period(gauge, reward_token);
        reward_per_gauge[gauge][reward_token] += reward_amount;
        _add(gauge, reward_token);
        emit RewardAdded(msg.sender, gauge, reward_token, reward_amount, fee_take);
        return true;
    }
    
    /// @notice Estimate pending bribe amount for any user
    /// @dev This function returns zero if active_period has not yet been updated.
    /// @dev Should not rely on this function for any user case where precision is required.
    function claimable(address user, address gauge, address reward_token) external view returns (uint) {
        uint _period = current_period();
        if(blacklist.contains(user) || next_claim_time[user] > _period) {
            return 0;
        }
        if (last_user_claim[user][gauge][reward_token] >= _period) {
            return 0;
        }
        uint last_user_vote = GAUGE.last_user_vote(user, gauge);
        if (last_user_vote >= _period) {
            return 0;
        }
        if (_period != active_period[gauge][reward_token]) {
            return 0;
        }
        GaugeController.VotedSlope memory vs = GAUGE.vote_user_slopes(user, gauge);
        uint _user_bias = _calc_bias(vs.slope, vs.end);
        return _user_bias * reward_per_token[gauge][reward_token] / PRECISION;
    }

    function claim_reward(address gauge, address reward_token) external returns (uint) {
        return _claim_reward(msg.sender, gauge, reward_token);
    }

    function claim_reward_for_many(address[] calldata _users, address[] calldata _gauges, address[] calldata _reward_tokens) external returns (uint[] memory amounts) {
        require(_users.length == _gauges.length && _users.length == _reward_tokens.length, "!lengths");
        uint length = _users.length;
        amounts = new uint[](length);
        for (uint i = 0; i < length; i++) {
            amounts[i] = _claim_reward(_users[i], _gauges[i], _reward_tokens[i]);
        }
        return amounts;
    }

    function claim_reward_for(address user, address gauge, address reward_token) external returns (uint) {
        return _claim_reward(user, gauge, reward_token);
    }
    
    function _claim_reward(address user, address gauge, address reward_token) internal returns (uint) {
        if(blacklist.contains(user) || next_claim_time[user] > current_period()){
            return 0;
        }
        uint _period = _update_period(gauge, reward_token);
        uint _amount = 0;
        if (last_user_claim[user][gauge][reward_token] < _period) {
            last_user_claim[user][gauge][reward_token] = _period;
            if (GAUGE.last_user_vote(user, gauge) < _period) {
                GaugeController.VotedSlope memory vs = GAUGE.vote_user_slopes(user, gauge);
                uint _user_bias = _calc_bias(vs.slope, vs.end);
                _amount = _user_bias * reward_per_token[gauge][reward_token] / PRECISION;
                if (_amount > 0) {
                    claims_per_gauge[gauge][reward_token] += _amount;
                    address recipient = reward_recipient[user];
                    recipient = recipient == address(0) ? user : recipient;
                    _safeTransfer(reward_token, recipient, _amount);
                    emit RewardClaimed(user, gauge, user, _amount);
                }
            }
        }
        return _amount;
    }

    /// @dev Compute bias from slope and lock end
    /// @param _slope User's slope
    /// @param _end Timestamp of user's lock end
    function _calc_bias(uint _slope, uint _end) internal view returns (uint) {
        uint current = current_period();
        if (current + WEEK >= _end) return 0;
        return _slope * (_end - current);
    }

    /// @dev Sum all blacklisted bias for any gauge in current period.
    function get_blacklisted_bias(address gauge) public view returns (uint) {
        uint bias;
        uint length = blacklist.length();
        for (uint i = 0; i < length; i++) {
            address user = blacklist.at(i);
            GaugeController.VotedSlope memory vs = GAUGE.vote_user_slopes(user, gauge);
            bias += _calc_bias(vs.slope, vs.end);
        }
        return bias;
    }

    /// @notice Allow owner to add address to blacklist, preventing them from claiming
    /// @dev Any vote weight address added
    function add_to_blacklist(address _user) external {
        require(msg.sender == owner, "!owner");
        if(blacklist.add(_user)) emit Blacklisted(_user);
    }

    /// @notice Allow owner to remove address from blacklist
    /// @dev We set a next_claim_time to prevent access to current period's bribes
    function remove_from_blacklist(address _user) external {
        require(msg.sender == owner, "!owner");
        if(blacklist.remove(_user)){
            next_claim_time[_user] = current_period() + WEEK;
            emit RemovedFromBlacklist(_user);
        }
    }

    /// @notice Check if address is blacklisted
    function is_blacklisted(address address_to_check) public view returns (bool) {
        return blacklist.contains(address_to_check);
    }

    /// @dev Helper function, if possible, avoid using on-chain as list can grow unbounded
    function get_blacklist() public view returns (address[] memory _blacklist) {
        _blacklist = new address[](blacklist.length());
        for (uint i; i < blacklist.length(); i++) {
            _blacklist[i] = blacklist.at(i);
        }
    }

    /// @dev Helper function to determine current period globally. Not specific to any gauges or internal state.
    function current_period() public view returns (uint) {
        return block.timestamp / WEEK * WEEK;
    }

    /// @notice Allow any user to route claimed rewards to a specified recipient address
    function set_recipient(address _recipient) external {
        require (_recipient != msg.sender, "self");
        require (_recipient != address(0), "0x0");
        address current_recipient = reward_recipient[msg.sender];
        require (_recipient != current_recipient, "Already set");
        
        // Update delegation mapping
        reward_recipient[msg.sender] = _recipient;
        
        if (current_recipient != address(0)) {
            emit ClearRewardRecipient(msg.sender, current_recipient);
        }

        emit SetRewardRecipient(msg.sender, _recipient);
    }

    /// @notice Allow any user to clear any previously specified reward recipient
    function clear_recipient() external {
        address current_recipient = reward_recipient[msg.sender];
        require (current_recipient != address(0), "No recipient set");
        // update delegation mapping
        reward_recipient[msg.sender]= address(0);
        emit ClearRewardRecipient(msg.sender, current_recipient);
    }

    /// @notice Allow owner to set fees of up to 4% of bribes upon deposit
    function set_fee_percent(uint _percent) external {
        require(msg.sender == owner, "!owner");
        require(_percent <= 400);
        fee_percent = _percent;
    }

    function set_fee_recipient(address _recipient) external {
        require(msg.sender == owner, "!owner");
        fee_recipient = _recipient;
    }

    function set_owner(address _new_owner) external {
        require(msg.sender == owner, "!owner");
        pending_owner = _new_owner;
    }

    function accept_owner() external {
        address _pending_owner = pending_owner;
        require(msg.sender == _pending_owner, "!pending_owner");
        owner = _pending_owner;
        emit ChangeOwner(_pending_owner);
        pending_owner = address(0);
    }

    function _safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}