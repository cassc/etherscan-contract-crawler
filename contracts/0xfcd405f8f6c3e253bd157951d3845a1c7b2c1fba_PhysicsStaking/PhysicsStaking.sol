/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface DividendPayingContractOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingContractInterface {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function withdrawDividend() external;
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

contract DividendPayingContract is DividendPayingContractInterface, DividendPayingContractOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
                                                                         
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  
  mapping (address => uint256) public holderBalance;
  uint256 public totalBalance;

  uint256 public totalDividendsDistributed;

  receive() external payable {
    distributeDividends();
  }

  function distributeDividends() public override payable {
    if(totalBalance > 0 && msg.value > 0){
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (msg.value).mul(magnitude) / totalBalance
        );
        emit DividendsDistributed(msg.sender, msg.value);

        totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  function withdrawDividend() external virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);

      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function dividendOf(address _owner) external view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) external view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;
    if(newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);
      _increase(account, increaseAmount);
      totalBalance += increaseAmount;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      _reduce(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }
}


contract DividendTracker is DividendPayingContract {

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() {}

    function getAccount(address _account)
        public view returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 balance) {
        account = _account;

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        balance = holderBalance[account];
    }

    function setBalance(address payable account, uint256 newBalance) internal {

        _setBalance(account, newBalance);

    	processAccount(account, true);
    }
    
    function processAccount(address payable account, bool automatic) internal returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return totalDividendsDistributed;
    }

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return holderBalance[account];
	}

    function getNumberOfDividends() external view returns(uint256) {
        return totalBalance;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
    bool public stakingOpen;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Context {
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PhysicsStaking is ReentrancyGuard, DividendTracker, Ownable {

    IERC20 public immutable physicsToken;
    IDexRouter public immutable dexRouter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.UintSet private stakingPeriodsInDays;
    mapping (uint256 => uint256) public stakingPeriodBoost;
    uint256 public emergencyWithdrawPenalty;

    struct User {
        uint112 withdrawableTokens;
        uint112 baseTokensStaked;
        uint112 holderUnlockTime;
        uint48 stakingDuration;
        bool blacklisted;
    }

    mapping (address => User) public users;
    EnumerableSet.AddressSet private userList;

    mapping (address => mapping(address =>EnumerableSet.UintSet)) private holderNftsStaked;
    
    IERC721 public nftAddress;
    uint256 public percBoostPerNft;
    uint256 public maxStakedNftsAllowed;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amountForUser, uint256 amountForPenalty);
    event StakedNFT(address indexed nftAddress, uint256 indexed tokenId, address indexed sender);
    event UnstakedNFT(address indexed nftAddress, uint256 indexed tokenId, address indexed sender);

    constructor(address _physicsToken) {
        require(_physicsToken != address(0), "cannot be 0 address");
        physicsToken = IERC20(_physicsToken);

        //@dev initialize staking periods and boosts
        stakingPeriodsInDays.add(30);
        stakingPeriodsInDays.add(90);
        stakingPeriodsInDays.add(180);
        stakingPeriodsInDays.add(360);
        stakingPeriodBoost[30] = 0;
        stakingPeriodBoost[90] = 30;
        stakingPeriodBoost[180] = 60;
        stakingPeriodBoost[360] = 120;

        // @dev set router for compounding
        address _v2Router;

        // @dev assumes WETH pair
        if(block.chainid == 1){
            _v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if(block.chainid == 5){
            _v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else {
            revert("Chain not configured");
        }

        dexRouter = IDexRouter(_v2Router);
        percBoostPerNft = 100;
        maxStakedNftsAllowed = 1;
        emergencyWithdrawPenalty = 50;
    }

    // Owner functions

    // @dev Blacklists (or unblacklists) list of users.  Tokens from blacklisted users will be transferred to owner's wallet and user will no longer be able to interact with contract.
    function setBlacklisted(address[] memory _addresses, bool _blacklisted) external onlyOwner {
        uint256 tokensToTransfer;
        for(uint256 i = 0; i < _addresses.length; i++){
            address addy = _addresses[i];
            User memory user = users[addy];
            if(_blacklisted){
                if(user.withdrawableTokens > 0){
                    tokensToTransfer += user.withdrawableTokens;
                }
                user.baseTokensStaked = 0;
                user.withdrawableTokens = 0;
                user.stakingDuration = 0;
                user.holderUnlockTime = 0;
                setBalance(payable(addy), 0);
            }
            if(userList.contains(addy)){
                userList.remove(addy);
            }
            user.blacklisted = _blacklisted;
            users[addy] = user;
        }
        if(tokensToTransfer > 0){
            physicsToken.transfer(address(owner()), tokensToTransfer);
        }
    }

    // @dev Revokes supplied list of users tokens and users keep earning ETH.
    function revokeTokens(address[] memory _addresses) external onlyOwner {
        uint256 tokensToTransfer;
        for(uint256 i = 0; i < _addresses.length; i++){
            address addy = _addresses[i];
            User storage user = users[addy];
            if(user.withdrawableTokens > 0){
                tokensToTransfer += user.withdrawableTokens;
                user.withdrawableTokens = 0;
            }
        }
        if(tokensToTransfer > 0){
            physicsToken.transfer(address(owner()), tokensToTransfer);
        }
    }

    // @dev Revokes all users tokens and users keep earning ETH.  List may eventually get too long for this function to work.  Use above function and do in batches if needed.
    function revokeAllTokens() external onlyOwner {
        address[] memory _addresses = getUserList();
        physicsToken.transfer(address(owner()), physicsToken.balanceOf(address(this)));
        for(uint256 i = 0; i < _addresses.length; i++){
            address addy = _addresses[i];
            User storage user = users[addy];
            if(user.withdrawableTokens > 0){
                user.withdrawableTokens = 0;
            }
        }
    }

    // @dev Sets early withdraw penalty percentage
    function updateEmergencyWithdrawPenalty(uint256 _newPerc) external onlyOwner {
        require(_newPerc <= 50, "Cannot set higher than 50%");
        emergencyWithdrawPenalty = _newPerc;
    }

    // @dev Sets NFT Boost Percentage per NFT
    function updatePercBoostPerNft(uint256 _newPerc) external onlyOwner {
        percBoostPerNft = _newPerc;
    }

    // @dev Sets the maximum number of NFTs that can be staked from a single collection
    function updateMaxNftsStaked(uint256 _newMax) external onlyOwner {
        maxStakedNftsAllowed = _newMax;
    }

    // @dev Updates the current NFT contract that allows staking for rewards
    function updateNftAddress(address _newNftAddress) external onlyOwner {
        nftAddress = IERC721(_newNftAddress);
    }

    // @dev Adds a new staking period along with the boosted percentage
    function addStakingPeriod(uint256 _newStakingPeriod, uint256 _newStakingBoost) external onlyOwner {
        require(!stakingPeriodsInDays.contains(_newStakingPeriod), "Staking Period already added");
        stakingPeriodsInDays.add(_newStakingPeriod);
        stakingPeriodBoost[_newStakingPeriod] = _newStakingBoost;
    }

    // @dev Removes an existing staking period. Avoid using this unless it's absolutely necessary as it will require users to extend their lock to get boosts.

    function removeStakingPeriod(uint256 _newStakingPeriod) external onlyOwner {
        require(stakingPeriodsInDays.contains(_newStakingPeriod), "Staking Period doesn't exist");
        stakingPeriodsInDays.remove(_newStakingPeriod);
        stakingPeriodBoost[_newStakingPeriod] = 0;
    }

    // @dev Updates the staking boost
    function updateStakingBoost(uint256 _stakingPeriod, uint256 _newStakingBoost) external onlyOwner {
        require(stakingPeriodsInDays.contains(_stakingPeriod), "Staking Period doesn't exist");
        stakingPeriodBoost[_stakingPeriod] = _newStakingBoost;
    }

    // @dev Use if switching staking boosts or NFT addresses to update existing users
    function forceUpdate(address[] memory _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++){
            address addy = _addresses[i];
            User memory user = users[addy];
            if(!user.blacklisted){
                setInternalBalance(addy, user);
            }
        }
    }

    // @dev List may eventually get too long for this function to work.  Use above function and do in batches if needed.
    function forceUpdateAll() external onlyOwner {
        address[] memory _addresses = getUserList();
        for(uint256 i = 0; i < _addresses.length; i++){
            address addy = _addresses[i];
            User memory user = users[addy];
            if(!user.blacklisted){
                setInternalBalance(addy, user);
            }
        }
    }

    // External User Functions

    // @dev Function for users to deposit tokens.  Staking Duration must be valid.  Tokens must be approved with staking contract as spender for transferFrom function to work.
    function deposit(uint256 _amount, uint48 _stakingDurationInDays) external nonReentrant {
        User memory user = users[msg.sender];
        require(_amount > 0, "Zero Amount");
        require(!user.blacklisted, "Blacklisted");
        require(stakingPeriodsInDays.contains(_stakingDurationInDays), "Invalid staking period");
        require(user.stakingDuration <= _stakingDurationInDays, "Cannot stake for a shorter period of time");
        if(!userList.contains(msg.sender)){
            userList.add(msg.sender);
        }

        user.stakingDuration = _stakingDurationInDays;
        user.holderUnlockTime = uint48(block.timestamp + (_stakingDurationInDays * 1 days));

        uint112 amountTransferred = 0;
        uint112 initialBalance = uint112(physicsToken.balanceOf(address(this)));
        physicsToken.transferFrom(address(msg.sender), address(this), _amount);
        amountTransferred = uint112(physicsToken.balanceOf(address(this)) - initialBalance);

        user.baseTokensStaked += amountTransferred;
        user.withdrawableTokens += amountTransferred;

        setInternalBalance(msg.sender, user); 

        emit Deposit(msg.sender, _amount);
        users[msg.sender] = user;
    }

    // @dev Function for users to extend lock.  Staking Duration must be valid.  Does not require any token transfer and immediately gives new bonus.
    function extendLock(uint48 _stakingDurationInDays) external nonReentrant {
        User memory user = users[msg.sender];
        require(!user.blacklisted, "Blacklisted");
        require(stakingPeriodsInDays.contains(_stakingDurationInDays), "Invalid staking period");
        require(user.stakingDuration <= _stakingDurationInDays, "Cannot stake for a shorter period of time");

        user.stakingDuration = _stakingDurationInDays;
        user.holderUnlockTime = uint48(block.timestamp + (_stakingDurationInDays * 1 days));

        setInternalBalance(msg.sender, user); 

        users[msg.sender] = user;
    }

    // @dev Function for users to withdraw tokens after unlock.  This stops all rewards for the wallet.
    function withdrawTokens() external nonReentrant {
        User memory user = users[msg.sender];
        require(!user.blacklisted, "Blacklisted");
        require(user.holderUnlockTime <= block.timestamp, "Too early");
        uint256 amount = user.withdrawableTokens;
        require(amount > 0, "No tokens with withdraw");

        user.baseTokensStaked = 0;
        user.withdrawableTokens = 0;
        user.stakingDuration = 0;
        user.holderUnlockTime = 0;
        users[msg.sender] = user;

        physicsToken.transfer(address(msg.sender), amount);

        setBalance(payable(msg.sender), 0);
        if(userList.contains(msg.sender)){
            userList.remove(msg.sender);
        }

        emit Withdraw(msg.sender, amount);
    }

    // @dev Function for users to withdraw tokens before unlock.  This stops all rewards for the wallet.  penalty
    function emergencyWithdrawTokens() external nonReentrant {
        User memory user = users[msg.sender];
        require(!user.blacklisted, "Blacklisted");
        uint256 amountForPenalty = user.withdrawableTokens * emergencyWithdrawPenalty / 100;
        uint256 amountForUser = user.withdrawableTokens - amountForPenalty;
        require(user.withdrawableTokens > 0, "No tokens with withdraw");

        user.baseTokensStaked = 0;
        user.withdrawableTokens = 0;
        user.stakingDuration = 0;
        user.holderUnlockTime = 0;
        users[msg.sender] = user;

        physicsToken.transfer(address(msg.sender), amountForUser);
        if(amountForPenalty > 0){
            physicsToken.transfer(address(owner()), amountForPenalty);
        }

        setBalance(payable(msg.sender), 0);
        if(userList.contains(msg.sender)){
            userList.remove(msg.sender);
        }

        emit EmergencyWithdraw(msg.sender, amountForUser, amountForPenalty);
    }

    // @dev Function which allows user to stake any current NFTs
    function stakeNfts(uint256[] calldata tokenIds) external nonReentrant {
        User memory user = users[msg.sender];
        require(!user.blacklisted, "Blacklisted");
        require(address(nftAddress) != address(0), "Nft Address not set");

        require(tokenIds.length + holderNftsStaked[address(nftAddress)][msg.sender].length() <= maxStakedNftsAllowed, "can't stake this many NFTs");

        for (uint256 i=0; i<tokenIds.length; i++){
            require(nftAddress.getApproved(tokenIds[i]) == address(this) || nftAddress.isApprovedForAll(msg.sender, address(this)), "Must approve token to be sent");
            nftAddress.transferFrom(msg.sender, address(this), tokenIds[i]);
            holderNftsStaked[address(nftAddress)][msg.sender].add(tokenIds[i]);
            emit StakedNFT(address(nftAddress), tokenIds[i], msg.sender);        
        }

        setInternalBalance(msg.sender, user);    
    }

    // @dev Function which allows user to withdraw any current NFTs
    function unstakeNfts(uint256[] calldata tokenIds) external nonReentrant {
        User memory user = users[msg.sender];
        require(!user.blacklisted, "Blacklisted");
        require(address(nftAddress) != address(0), "Nft Address not set");

        for (uint256 i=0; i<tokenIds.length; i++){
            require(holderNftsStaked[address(nftAddress)][msg.sender].contains(tokenIds[i]), "Nft not owned");
            nftAddress.transferFrom(address(this), msg.sender, tokenIds[i]);
            holderNftsStaked[address(nftAddress)][msg.sender].remove(tokenIds[i]);
            emit UnstakedNFT(address(nftAddress), tokenIds[i], msg.sender);        
        }

        setInternalBalance(msg.sender, user);     
    }

    // @dev Function which allows user to withdraw any previous NFTs
    function emergencyWithdrawNfts(uint256[] calldata tokenIds, address _nftAddress) external nonReentrant {
        User memory user = users[msg.sender];
        require(address(_nftAddress) != address(0) && _nftAddress != address(nftAddress), "Nft Address not correct");

        for (uint256 i=0; i<tokenIds.length; i++){
            require(holderNftsStaked[address(_nftAddress)][msg.sender].contains(tokenIds[i]), "Nft not owned");
            IERC721(_nftAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
            holderNftsStaked[address(_nftAddress)][msg.sender].remove(tokenIds[i]);
            emit UnstakedNFT(address(_nftAddress), tokenIds[i], msg.sender);        
        }

        setInternalBalance(msg.sender, user);     
    }

    // @dev Function which with lets user claim pending ETH.
    function claim() external nonReentrant {
        processAccount(payable(msg.sender), false);
    }

    // @dev Function which allows users to compound their pending ETH rewards for more stake
    function compound(uint256 minOutput) external nonReentrant {
        User storage user = users[msg.sender];
        require(!user.blacklisted, "Blacklisted");
        uint256 amountEthForCompound = _withdrawDividendOfUserForCompound(payable(msg.sender));
        if(amountEthForCompound > 0){
            uint256 initialBalance = physicsToken.balanceOf(address(this));
            buyBackTokens(amountEthForCompound, minOutput);
            uint112 amountTransferred = uint112(physicsToken.balanceOf(address(this)) - initialBalance);
            user.baseTokensStaked += amountTransferred;
            setInternalBalance(msg.sender, user);
        } else {
            revert("No rewards");
        }
    }

    // internal functions

    // @dev Updates internal withdrawn dividend for compound usage only
    function _withdrawDividendOfUserForCompound(address payable user) internal returns (uint256 _withdrawableDividend) {
        _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user] + _withdrawableDividend;
            emit DividendWithdrawn(user, _withdrawableDividend);
        }
    }

    // @dev Buys tokens for compounding
    function buyBackTokens(uint256 ethAmountInWei, uint256 minOut) internal {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(physicsToken);

        // make the swap
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmountInWei}(
            minOut,
            path,
            address(this),
            block.timestamp
        );
    }

    // @dev helper function to keep formula for balances consistent

    function setInternalBalance(address _address, User memory user) internal {
        if(user.blacklisted){
            setBalance(payable(_address), 0);
        } else {
            setBalance(payable(_address), user.baseTokensStaked * 
                    (100 + stakingPeriodBoost[user.stakingDuration]) / 
                    100*
                    getStakingMultiplier(_address) / 
                    100);
        }
    }

    // views

    // @dev View used to compute compound with eth amount as parameter
    function getExpectedCompoundOutputByEthAmount(uint256 rewardAmount) external view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(physicsToken);
        uint256[] memory amounts = dexRouter.getAmountsOut(rewardAmount, path);
        return amounts[1];
    }

    // @dev View used to compute compound with wallet as parameter
    function getExpectedCompoundOutputByWallet(address wallet) external view returns(uint256) {
        uint256 rewardAmount = withdrawableDividendOf(wallet);
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(physicsToken);
        uint256[] memory amounts = dexRouter.getAmountsOut(rewardAmount, path);
        return amounts[1];
    }

    // @dev View used to get the user's staking multiplier from NFTs.  Divide by 100 after multiplying.
    function getStakingMultiplier(address holder) public view returns (uint256) {
        if(holderNftsStaked[address(nftAddress)][holder].length() == 0){
            return 100;
        }
        // additive boost per NFT staked
        return 100 + (holderNftsStaked[address(nftAddress)][holder].length()*percBoostPerNft);
    }


    // @dev View used to return all important information related to a user
    function getUser(address _user) external view returns (User memory user,
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 balance) {
        (account, withdrawableDividends, totalDividends, balance) = getAccount(_user);
        user = users[_user];
    }

    // @dev View returns list (in days) of all valid staking periods
    function getValidStakingDurations() external view returns (uint256[] memory){
        return stakingPeriodsInDays.values();
    }

    // @dev View returns list of all current stakers
    function getUserList() public view returns (address[] memory){
        return userList.values();
    }

    // @dev View fetches all NFTs staked with current set nft contract by user
    function getUserStakedNfts(address _user) external view returns (uint256[] memory){
        return holderNftsStaked[address(nftAddress)][_user].values();
    }

    // @dev View for use if the NFT address changes, people can still look up their old NFTs and withdraw them
    function getUserStakedNftsByNftAddress(address _nftAddress, address _user) external view returns (uint256[] memory){
        return holderNftsStaked[_nftAddress][_user].values();
    }
 }