/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT

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

// File: ryoshimultisign.sol

pragma solidity ^0.8.0;



contract RyoshiMultisig {

    uint constant public MAX_OWNERS = 10;

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredConfirmations;

    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 indexed requiredConfirmations);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredConfirmations) {
        require(_owners.length <= MAX_OWNERS, "Too many owners");
        require(_requiredConfirmations > 0 && _requiredConfirmations <= _owners.length, "Invalid confirmation requirements");

        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        requiredConfirmations = _requiredConfirmations;
    }

    receive() external payable {}

    function submitTransaction(address _destination, uint256 _value, bytes memory _data) external onlyOwner returns (uint256) {
        uint256 transactionId = addTransaction(_destination, _value, _data);
        confirmTransaction(transactionId);
        return transactionId;
    }

    function confirmTransaction(uint256 _transactionId) public onlyOwner {
        require(!confirmations[_transactionId][msg.sender], "Already confirmed");
        confirmations[_transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, _transactionId);
    }

    function executeTransaction(uint256 _transactionId) public onlyOwner {
        require(transactions[_transactionId].executed == false, "Already executed");
        if (isConfirmed(_transactionId)) {
            Transaction storage txn = transactions[_transactionId];
            txn.executed = true;
            (bool success,) = txn.destination.call{value: txn.value}(txn.data);
            if (success) {
                emit Execution(_transactionId);
            } else {
                emit ExecutionFailure(_transactionId);
                txn.executed = false;
            }
        }
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function isConfirmed(uint256 _transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[_transactionId][owners[i]]) {
                count += 1;
            }
            if (count == requiredConfirmations) {
                return true;
            }
        }
        return false;
    }

    function addTransaction(address _destination, uint256 _value, bytes memory _data) internal returns (uint256) {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: _destination,
            value: _value,
            data: _data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }
}