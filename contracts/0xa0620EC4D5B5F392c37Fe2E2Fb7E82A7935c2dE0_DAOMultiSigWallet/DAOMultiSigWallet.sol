/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: multisig.sol


pragma solidity ^0.8.0;


contract DAOMultiSigWallet {
    using SafeMath for uint256;

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredSignatures;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    // Events
    event OwnerAdded(address owner);
    event OwnerRemoved(address owner);
    event TransactionCreated(uint256 txId, address destination, uint256 value, bytes data);
    event TransactionConfirmed(uint256 txId, address owner);
    event TransactionExecuted(uint256 txId);

    // Modifiers
    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner does not exist.");
        _;
    }

    modifier transactionExists(uint256 txId) {
        require(transactions.length > txId, "Transaction does not exist.");
        _;
    }

    modifier notConfirmed(uint256 txId, address owner) {
        require(!confirmations[txId][owner], "Transaction already confirmed.");
        _;
    }

    // Constructor
    constructor(address[] memory _owners, uint256 _requiredSignatures) {
        require(_owners.length >= _requiredSignatures && _requiredSignatures > 0);
        
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]]); // Check for duplicates
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        requiredSignatures = _requiredSignatures;
    }

    // Fallback function
    receive() external payable {}

    // Add an owner
    function addOwner(address _owner) external ownerExists(msg.sender) {
        require(!isOwner[_owner], "Owner already exists.");
        isOwner[_owner] = true;
        owners.push(_owner);
        emit OwnerAdded(_owner);
    }

    // Remove an owner
    function removeOwner(address _owner) external ownerExists(msg.sender) ownerExists(_owner) {
        isOwner[_owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        emit OwnerRemoved(_owner);
    }

    // Create a transaction
    function createTransaction(address _destination, uint256 _value, bytes memory _data) external ownerExists(msg.sender) {
        uint256 txId = transactions.length;
        transactions.push(Transaction({
            destination: _destination,
            value: _value,
            data: _data,
            executed: false
        }));
        emit TransactionCreated(txId, _destination, _value, _data);
    }

    // Confirm a transaction
    function confirmTransaction(uint256 _txId) external ownerExists(msg.sender) transactionExists(_txId) notConfirmed(_txId, msg.sender) {
        confirmations[_txId][msg.sender] = true;
        emit TransactionConfirmed(_txId, msg.sender);
    }

    // Execute a transaction
    function executeTransaction(uint256 _txId) external ownerExists(msg.sender) transactionExists(_txId) {
        Transaction storage tx = transactions[_txId];
        require(!tx.executed, "Transaction already executed.");
        
        uint256 confirmedOwners = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[_txId][owners[i]]) confirmedOwners++;
            if (confirmedOwners >= requiredSignatures) break;
        }

        require(confirmedOwners >= requiredSignatures, "Not enough confirmations.");

        (bool success, ) = tx.destination.call{value: tx.value}(tx.data);
        require(success, "Transaction execution failed.");

        tx.executed = true;
        emit TransactionExecuted(_txId);
    }
}