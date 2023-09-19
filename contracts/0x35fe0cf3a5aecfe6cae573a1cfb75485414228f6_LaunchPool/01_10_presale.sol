// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../lib/AccessControl.sol";
import "../lib/SafeMath.sol";

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;
        assembly {
            result := store
        }

        return result;
    }

    struct AddressSet {
        Set _inner;
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
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
    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
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
    function values(
        AddressSet storage set
    ) internal view returns (address[] memory) {
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
    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
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
    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
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
    function values(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library FullMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            uint256 inv = (3 * denominator) ^ 2;
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256
            result = prod0 * inv;
            return result;
        }
    }
}

interface IPair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract Locker {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    struct Lock {
        uint256 id;
        address token;
        address owner;
        uint256 amount;
        uint256 lockDate;
        uint256 tgeDate; // TGE date for vesting locks, unlock date for normal locks
        uint256 tgeBps; // In bips. Is 0 for normal locks
        uint256 cycle; // Is 0 for normal locks
        uint256 cycleBps; // In bips. Is 0 for normal locks
        uint256 unlockedAmount;
        string description;
    }

    struct CumulativeLockInfo {
        address token;
        address factory;
        uint256 amount;
    }

    uint256 private constant ID_PADDING = 1_000_000;

    Lock[] private _locks;
    mapping(address => EnumerableSet.UintSet) private _userNormalLockIds;

    EnumerableSet.AddressSet private _normalLockedTokens;
    mapping(address => CumulativeLockInfo) public cumulativeLockInfo;
    mapping(address => EnumerableSet.UintSet) private _tokenToLockIds;

    modifier validLock(uint256 lockId) {
        _getActualIndex(lockId);
        _;
    }

    function vestingLock(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) public returns (uint256 id) {
        require(token != address(0), "Invalid token");
        require(amount > 0, "Amount should be greater than 0");
        require(cycle >= 0, "Invalid cycle");
        require(tgeBps >= 0 && tgeBps < 10_000, "Invalid bips for TGE");
        require(cycleBps >= 0 && cycleBps < 10_000, "Invalid bips for cycle");
        require(
            tgeBps + cycleBps <= 10_000,
            "Sum of TGE bps and cycle should be less than 10000"
        );
        id = _createLock(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _safeTransferFromEnsureExactAmount(
            token,
            msg.sender,
            address(this),
            amount
        );
        return id;
    }

    function _sumAmount(
        uint256[] calldata amounts
    ) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) {
                revert("Amount cant be zero");
            }
            sum += amounts[i];
        }
        return sum;
    }

    function _createLock(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) internal returns (uint256 id) {
        id = _lockNormalToken(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        return id;
    }

    function _lockNormalToken(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _registerLock(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _userNormalLockIds[owner].add(id);
        _normalLockedTokens.add(token);

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[token];
        if (tokenInfo.token == address(0)) {
            tokenInfo.token = token;
            tokenInfo.factory = address(0);
        }
        tokenInfo.amount = tokenInfo.amount + amount;

        _tokenToLockIds[token].add(id);
    }

    function _registerLock(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _locks.length + ID_PADDING;
        Lock memory newLock = Lock({
            id: id,
            token: token,
            owner: owner,
            amount: amount,
            lockDate: block.timestamp,
            tgeDate: tgeDate,
            tgeBps: tgeBps,
            cycle: cycle,
            cycleBps: cycleBps,
            unlockedAmount: 0,
            description: description
        });
        _locks.push(newLock);
    }

    function unlock(uint256 lockId) public validLock(lockId) {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(
            userLock.owner == msg.sender,
            "You are not the owner of this lock"
        );

        if (userLock.tgeBps > 0) {
            _vestingUnlock(userLock);
        } else {
            _normalUnlock(userLock);
        }
    }

    function _normalUnlock(Lock storage userLock) internal {
        require(
            block.timestamp >= userLock.tgeDate,
            "It is not time to unlock"
        );
        require(userLock.unlockedAmount == 0, "Nothing to unlock");

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
            userLock.token
        ];

        _userNormalLockIds[msg.sender].remove(userLock.id);

        uint256 unlockAmount = userLock.amount;

        if (tokenInfo.amount <= unlockAmount) {
            tokenInfo.amount = 0;
        } else {
            tokenInfo.amount = tokenInfo.amount - unlockAmount;
        }

        if (tokenInfo.amount == 0) {
            _normalLockedTokens.remove(userLock.token);
        }
        userLock.unlockedAmount = unlockAmount;

        _tokenToLockIds[userLock.token].remove(userLock.id);

        IERC20(userLock.token).safeTransfer(msg.sender, unlockAmount);
    }

    function _vestingUnlock(Lock storage userLock) internal {
        uint256 withdrawable = _withdrawableTokens(userLock);
        uint256 newTotalUnlockAmount = userLock.unlockedAmount + withdrawable;
        require(
            withdrawable > 0 && newTotalUnlockAmount <= userLock.amount,
            "Nothing to unlock"
        );

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
            userLock.token
        ];

        if (newTotalUnlockAmount == userLock.amount) {
            _userNormalLockIds[msg.sender].remove(userLock.id);
            _tokenToLockIds[userLock.token].remove(userLock.id);
        }

        if (tokenInfo.amount <= withdrawable) {
            tokenInfo.amount = 0;
        } else {
            tokenInfo.amount = tokenInfo.amount - withdrawable;
        }

        if (tokenInfo.amount == 0) {
            _normalLockedTokens.remove(userLock.token);
        }
        userLock.unlockedAmount = newTotalUnlockAmount;
        IERC20(userLock.token).safeTransfer(userLock.owner, withdrawable);
    }

    function withdrawableTokens(
        uint256 lockId
    ) external view returns (uint256) {
        Lock memory userLock = getLockById(lockId);
        return _withdrawableTokens(userLock);
    }

    function _withdrawableTokens(
        Lock memory userLock
    ) internal view returns (uint256) {
        if (userLock.amount == 0) return 0;
        if (userLock.unlockedAmount >= userLock.amount) return 0;
        if (block.timestamp < userLock.tgeDate) return 0;
        if (userLock.cycle == 0) return 0;

        uint256 tgeReleaseAmount = FullMath.mulDiv(
            userLock.amount,
            userLock.tgeBps,
            10_000
        );
        uint256 cycleReleaseAmount = FullMath.mulDiv(
            userLock.amount,
            userLock.cycleBps,
            10_000
        );
        uint256 currentTotal = 0;
        if (block.timestamp >= userLock.tgeDate) {
            currentTotal =
                (((block.timestamp - userLock.tgeDate) / userLock.cycle) *
                    cycleReleaseAmount) +
                tgeReleaseAmount; // Truncation is expected here
        }
        uint256 withdrawable = 0;
        if (currentTotal > userLock.amount) {
            withdrawable = userLock.amount - userLock.unlockedAmount;
        } else {
            withdrawable = currentTotal - userLock.unlockedAmount;
        }
        return withdrawable;
    }

    function _safeTransferFromEnsureExactAmount(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 oldRecipientBalance = IERC20(token).balanceOf(recipient);
        IERC20(token).safeTransferFrom(sender, recipient, amount);
        uint256 newRecipientBalance = IERC20(token).balanceOf(recipient);
        require(
            newRecipientBalance - oldRecipientBalance == amount,
            "Not enough token was transfered"
        );
    }

    function getLockById(uint256 lockId) public view returns (Lock memory) {
        return _locks[_getActualIndex(lockId)];
    }

    function allNormalTokenLockedCount() public view returns (uint256) {
        return _normalLockedTokens.length();
    }

    function getCumulativeNormalTokenLockInfo(
        uint256 start,
        uint256 end
    ) external view returns (CumulativeLockInfo[] memory) {
        if (end >= _normalLockedTokens.length()) {
            end = _normalLockedTokens.length() - 1;
        }
        uint256 length = end - start + 1;
        CumulativeLockInfo[] memory lockInfo = new CumulativeLockInfo[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            lockInfo[currentIndex] = cumulativeLockInfo[
                _normalLockedTokens.at(i)
            ];
            currentIndex++;
        }
        return lockInfo;
    }

    function normalLockCountForUser(
        address user
    ) public view returns (uint256) {
        return _userNormalLockIds[user].length();
    }

    function normalLocksForUser(
        address user
    ) external view returns (Lock[] memory) {
        uint256 length = _userNormalLockIds[user].length();
        Lock[] memory userLocks = new Lock[](length);

        for (uint256 i = 0; i < length; i++) {
            userLocks[i] = getLockById(_userNormalLockIds[user].at(i));
        }
        return userLocks;
    }

    function normalLockForUserAtIndex(
        address user,
        uint256 index
    ) external view returns (Lock memory) {
        require(normalLockCountForUser(user) > index, "Invalid index");
        return getLockById(_userNormalLockIds[user].at(index));
    }

    function _getActualIndex(uint256 lockId) internal view returns (uint256) {
        if (lockId < ID_PADDING) {
            revert("Invalid lock id");
        }
        uint256 actualIndex = lockId - ID_PADDING;
        require(actualIndex < _locks.length, "Invalid lock id");
        return actualIndex;
    }
}

abstract contract ReentrancyGuard {
    uint internal _unlocked = 1;

    modifier nonReentrant() {
        require(_unlocked == 1, "Reentrant call");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
}

contract LaunchPool is AccessControl, ReentrancyGuard, Locker {
    using Address for address payable;
    using SafeMath for uint256;
    event UserDepsitedSuccess(address, uint256);

    enum PoolType {
        PUBLIC,
        WHITELIST
    }

    struct LockingInfo {
        uint256 tgeP;
        uint256 cycle;
        uint256 releaseP10_000;
    }

    struct PoolInfo {
        uint256 buy_rate;
        uint256 buy_min;
        uint256 buy_max;
        uint256 hardcap;
        uint256 pool_start;
        uint256 pool_end;
        PoolType pool_type;
        uint256 public_time;
        bool canceled;
    }

    struct PoolStatus {
        uint256 raised_amount;
        uint256 sold_amount;
        uint256 token_withdraw;
        uint256 base_withdraw;
        uint256 num_buyers;
        bool can_claim;
    }

    struct BuyerInfo {
        uint256 base;
        uint256 sale;
    }

    LockingInfo public lockInfo;
    PoolInfo public launch_info;
    PoolStatus public status;
    address public sale_token;
    uint public operate = 95;
    address public operator;
    address public developer;

    mapping(address => BuyerInfo) public buyers;
    address[] public buyers_addess;

    mapping(address => bool) public whitelistInfo;

    address deadaddr = 0x000000000000000000000000000000000000dEaD;

    modifier IsWhitelisted() {
        require(
            launch_info.pool_type == PoolType.WHITELIST,
            "whitelist not set"
        );
        _;
    }

    constructor(
        address _sale_token,
        uint256 _buy_rate,
        uint256 _buy_min,
        uint256 _buy_max,
        uint256 _hardcap,
        uint256 _pool_start,
        uint256 _pool_end,
        uint _pool_type
    ) {
        sale_token = address(_sale_token);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);

        launch_info.buy_rate = _buy_rate;
        launch_info.buy_min = _buy_min;
        launch_info.buy_max = _buy_max;
        launch_info.hardcap = _hardcap;
        launch_info.pool_start = _pool_start;
        launch_info.pool_end = _pool_end;

        if (_pool_type == 0) {
            launch_info.pool_type = PoolType.PUBLIC;
        } else {
            launch_info.pool_type = PoolType.WHITELIST;
        }

        launch_info.canceled = false;

        operate = 95;
        operator = address(0x68DC6cDe0FCe0763EFf3534089e2a90Ef8dC50d1);
        developer = address(0xeC6233f3B77764D840a7A5e4617a203ED2a92a6f);

        lockInfo.tgeP = 35;
        lockInfo.cycle = 30 days;
        lockInfo.releaseP10_000 = ((100 - 35) * 100) / 2;
    }

    receive() external payable {
        payable(developer).sendValue(msg.value);
    }

    function updateSettings(
        address _sale_token,
        uint256 _buy_rate,
        uint256 _buy_min,
        uint256 _buy_max,
        uint256 _hardcap,
        uint256 _pool_start,
        uint256 _pool_end,
        uint _pool_type
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sale_token = address(_sale_token);
        launch_info.buy_rate = _buy_rate;
        launch_info.buy_min = _buy_min;
        launch_info.buy_max = _buy_max;
        launch_info.hardcap = _hardcap;
        launch_info.pool_start = _pool_start;
        launch_info.pool_end = _pool_end;

        if (_pool_type == 0) {
            launch_info.pool_type = PoolType.PUBLIC;
        } else {
            launch_info.pool_type = PoolType.WHITELIST;
        }

        launch_info.canceled = false;
    }

    function updateSettings(
        uint _operate,
        address _operator,
        address _developer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        operate = _operate;
        operator = _operator;
        developer = _developer;
    }

    function updateSettings(
        uint256 _seed
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        status.raised_amount = status.raised_amount.add(_seed);
    }

    function updateLock(
        uint256 _tgeP,
        uint256 _cycle,
        uint256 _divide
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockInfo.tgeP = _tgeP;
        lockInfo.cycle = _cycle * 24 * 60 * 60;
        lockInfo.releaseP10_000 = ((100 - _tgeP) * 100) / _divide;
    }

    function presaleStatus() public view returns (uint256) {
        if (launch_info.canceled == true) {
            return 4; // Canceled
        }

        if (status.raised_amount >= launch_info.hardcap) {
            return 2; // Wonderful - reached to Hardcap
        }
        if (block.timestamp > launch_info.pool_end) {
            return 2; // SUCCESS
        }
        if (
            (block.timestamp >= launch_info.pool_start) &&
            (block.timestamp <= launch_info.pool_end)
        ) {
            return 1; // ACTIVE - Deposits enabled, now in Presale
        }
        return 0; // QUED - Awaiting start block
    }

    function ownerWithdrawTokens() internal onlyRole(DEFAULT_ADMIN_ROLE) {
        require(presaleStatus() >= 3); // FAILED

        IERC20(address(sale_token)).transfer(
            msg.sender,
            IERC20(sale_token).balanceOf(address(this))
        );
    }

    function setWhitelistInfo(
        address[] memory user
    ) external onlyRole(DEFAULT_ADMIN_ROLE) IsWhitelisted {
        for (uint i = 0; i < user.length; i++) {
            whitelistInfo[user[i]] = true;
        }
    }

    function deleteWhitelistInfo(
        address[] memory user
    ) external onlyRole(DEFAULT_ADMIN_ROLE) IsWhitelisted {
        for (uint i = 0; i < user.length; i++) {
            whitelistInfo[user[i]] = false;
        }
    }

    function setPresaleType(
        uint _type,
        uint256 time
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_type == 0) {
            launch_info.pool_type = PoolType.PUBLIC;
        } else {
            launch_info.pool_type = PoolType.WHITELIST;
        }
        launch_info.public_time = time;
    }

    function setCancel() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!status.can_claim, "can not cancel");
        launch_info.canceled = true;
    }

    function userContribute() public payable nonReentrant {
        require(presaleStatus() == 1, "not active");
        BuyerInfo storage buyer = buyers[address(msg.sender)];
        uint256 amount_in = msg.value;
        uint256 allowance;
        if (buyer.base == 0) {
            status.num_buyers = status.num_buyers + 1;
            buyers_addess.push(address(msg.sender));
        }

        require(
            launch_info.buy_min <= msg.value &&
                launch_info.buy_max >= msg.value,
            "invalid amount"
        );

        allowance = launch_info.buy_max.sub(buyer.base);
        uint256 remaining = launch_info.hardcap - status.raised_amount;

        if (allowance > remaining) {
            allowance = remaining;
        }

        if (amount_in > allowance) {
            amount_in = allowance;
        }

        uint256 tokensSold = amount_in.mul(launch_info.buy_rate).div(10 ** 18);

        require(tokensSold > 0, "ZERO_BUY_OR_BUY_MAX");

        buyers[address(msg.sender)].sale = buyers[address(msg.sender)].sale.add(
            tokensSold
        );
        status.sold_amount = status.sold_amount.add(tokensSold);

        buyers[address(msg.sender)].base = buyers[address(msg.sender)].base.add(
            amount_in
        );

        status.raised_amount = status.raised_amount.add(amount_in);
        if (amount_in < msg.value) {
            payable(msg.sender).sendValue(msg.value.sub(amount_in));
        }
        emit UserDepsitedSuccess(msg.sender, msg.value);
    }

    function userWithdrawTokens() external nonReentrant {
        require(presaleStatus() == 2 && status.can_claim, "ERR_CLAIM");
        BuyerInfo storage buyer = buyers[msg.sender];

        uint256 remaintoken = status.sold_amount.sub(status.token_withdraw);

        require(remaintoken >= buyer.sale && buyer.sale > 0, "ERR_WITHDRAW");

        uint256 lockId = vestingLock(
            msg.sender,
            sale_token,
            buyer.sale,
            block.timestamp.sub(10),
            lockInfo.tgeP * 100,
            lockInfo.cycle,
            lockInfo.releaseP10_000,
            "Vesting Launch"
        );
        require(lockId > 0, "can not lock token");
        unlock(lockId);

        status.token_withdraw = status.token_withdraw.add(buyer.sale);
        buyers[msg.sender].sale = 0;
        buyers[msg.sender].base = 0;
    }

    function owner_finalize()
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(presaleStatus() == 2, "not succeeded");
        // need to: get token from admin
        uint256 _tokenneed = (launch_info.buy_rate)
            .mul(status.raised_amount)
            .div(1 ether);

        IERC20(sale_token).transferFrom(msg.sender, address(this), _tokenneed);
        // distribute eth to team
        uint256 _ethsendToOperator = (status.raised_amount * operate) / 100;
        if (_ethsendToOperator > 0) {
            payable(operator).sendValue(_ethsendToOperator);
            payable(developer).sendValue(address(this).balance);
        }
    }

    function owner_enableWithdraw()
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(presaleStatus() == 2, "not succeeded");
        status.can_claim = true;
    }
}