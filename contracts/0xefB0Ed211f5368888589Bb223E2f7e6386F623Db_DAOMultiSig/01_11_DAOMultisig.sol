// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import './IAccessController.sol';

/// @title a contract to use multisig approach to send some transactions for DAO: withdraw,
/// set swap fee, upgrade, etc.
/// @author Dexpresso Team
/// @notice we have 64 DaoMember in the most extreme case. Each DaoMember is able to
/// create, approve,disapprove, revoke and execute
/// transactions. Each DaoMember can have 3 active pending transaction at a time.
/// @dev transaction ids start from 1, and zero value for txId means no transaction found
/// the only array we have, is pendingTransactions which has 64*3 items length at most
contract DAOMultiSig is IAccessController, Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    // State Variables


    uint256 public transactionsCount;
    address internal newImplAddress;
    // minimum number of approvals needed to execute a transaction
    int8 public quorum;
    uint8 public daoMembersCount;
    mapping(address => bool) public isDaoMember;

    /// @notice to track each daoMember's pending transaction if exists
    /// @dev transaction ids start from 1 and zero value indicates that
    /// there is no pending transaction for this daoMember
    mapping(address => uint8) private pendingTransactionsByDaoMember;

    /// @notice to track if an daoMember has approved a transaction
    /// @dev address maps to transaction id and it maps to a number between(1, 0, -1)
    /// indicating if the address approved, disaprove a specific transaction or has not voted
    mapping(address => mapping(uint256 => int8)) public txApprovalByDaoMember;

    /// @notice storing pending transactions ids in pendingTransactions array
    /// @dev this array has at most 64*5 items, since we have 64 daoMembers maximum
    /// and each daoMember can have just 5 active pending transaction at a time
    uint256[] internal pendingTransactions;

    // a mapping from transaction Id to its transaction object
    mapping(uint256 => Transaction) internal transactions;

    // Structs && Enums

    // supported different types of transactions in a multisig manner
    enum TransactionType {
        WITHDRAW,
        WITHDRAW_ALL,
        ADD_DAO_MEMBER,
        DELETE_DAO_MEMBER,
        UPDATE_QUORUM,
        SET_SWAPPER_FEE,
        UNPAUSE_SWAPPER,
        PROPOSE_SWAPPER_ADMIN,
        ACCEPT_SWAPPER_ADMIN,
        UPGRADE_DAO_MULTISIG
    }

    enum TransactionStatus {
        PENDING,
        EXECUTED,
        REVOKED,
        REJECTED,
        EXPIRED
    }

    enum Filter {
        NONE,
        APPROVED,
        DISAPPROVED
    }

    // fields of a transaction, organized in a gas-efficient way
    struct Transaction {
        address from;
        TransactionType txType;
        TransactionStatus status;
        int8 approvals;
        uint64 validUntil;
        bytes data;
    }

    // fields of a pending transaction, gets fetched from web3
    struct PendingTx {
        uint256 id;
        address from;
        TransactionType txType;
        int8 vote;
        int8 approvals;
        uint64 validUntil;
        bytes data;
    }

    // Events && Errors

    event TransactionCreated(address indexed by, uint256 indexed txId);
    event TransactionApproved(address indexed by, uint256 indexed txId);
    event TransactionDisapproved(address indexed by, uint256 indexed txId);
    event TransactionExecuted(address indexed by, uint256 indexed txId);
    event TransactionRevoked(address indexed by, uint256 indexed txId);
    event ApprovalRevoked(address indexed by, uint256 indexed txId);
    event DisApprovalRevoked(address indexed by, uint256 indexed txId);
    event ERC20UnsuccessfulTransfer(address token);
    event EthTransferStatus(bool);

    // A custom error, thrown when an daoMember wants to issue a new transaction
    // while having three active pending transactions
    error ExceedsMaxNumberOfPendingTxs();
    error ERC20CallReverted(address token);

    // Modifiers

    modifier onlyDaoMember() {
        require(isDaoMember[msg.sender], 'ERROR: invalid caller');
        _;
    }

    modifier notZeroAddress(address account) {
        require(account != address(0), 'ERROR: invalid address');
        _;
    }
    modifier isValidPendingTx(uint256 txId) {
        // txId = 0 is not a valid transaction Id (valid txId starts from 1)
        require(txId > 0 && txId <= transactionsCount, 'ERROR: txId not found');
        require(transactions[txId].status == TransactionStatus.PENDING, 'ERROR: not a valid pending transaction');
        require(transactions[txId].validUntil >= block.timestamp, 'ERROR: expired transaction');
        _;
    }

    modifier canCreateTransaction() {
        uint8 pendingCount = pendingTransactionsByDaoMember[msg.sender];
        // max number of pending transactions per daoMember is 5
        if (pendingCount >= 5) {
            revert ExceedsMaxNumberOfPendingTxs();
        }
        _;
    }

    // Constructor and Functions

    /// @dev don't include msg.sender address in _daoMember and don't use repetitive
    /// addresses in this parameter
    /// @param _daoMember list of Dao Member including less than 128 addresses who
    /// can approve transactions
    /// we have maximum 64 daoMembers
    /// @param _quorum minimum number of daoMembers needed to execute a transaction
    function initialize(address[] memory _daoMember, uint8 _quorum) public initializer onlyProxy {
        require(_daoMember.length < 64, 'ERROR: number of DAO members is more than expected');
        require(_quorum <= _daoMember.length, 'ERROR: invalid quorum');
        for (uint8 i = 0; i < _daoMember.length; i++) {
            require(_daoMember[i] != address(0), 'ERROR: invalid daoMember');
            require(!isDaoMember[_daoMember[i]], 'ERROR: not unique daoMember');
            isDaoMember[_daoMember[i]] = true;
        }
        quorum = int8(_quorum);
        daoMembersCount = uint8(_daoMember.length);
    }

    /// @notice a valid caller can create a transaction to withdraw assets,
    /// waiting for getting enough approvals
    /// @dev max number of tokens to withdraw from, is 32 - msg.sender mustn't
    /// have more than 3 pending transactions
    /// @param receiver the address assets transfer to
    /// @param tokens list of ERC20 asset addresses (up to 32 addresses)
    /// @param amounts list of amounts to withdraw in the order of token addresses
    function createWithdrawTransaction(
        address receiver,
        address[] memory tokens,
        uint256[] memory amounts
    ) external virtual onlyDaoMember notZeroAddress(receiver) canCreateTransaction onlyProxy {
        require(tokens.length == amounts.length && tokens.length > 0 && tokens.length <= 32, 'ERROR: invalid input');
        bytes memory data = abi.encode(receiver, tokens, amounts);
        _createTransaction(TransactionType.WITHDRAW, data);
    }

    /// @notice a valid caller can create a transaction to empty out contract,
    /// waiting for getting enough approvals
    /// @dev max number of tokens to withdraw from, is 64 - msg.sender mustn't
    /// have more than 3 pending transactions
    /// @param receiver the address assets transfer to
    /// @param tokens list of ERC20 asset addresses (up to 64 addresses)
    function createWithdrawAllTransaction(
        address receiver,
        address[] memory tokens
    ) external virtual onlyDaoMember notZeroAddress(receiver) canCreateTransaction onlyProxy {
        require(tokens.length > 0 && tokens.length <= 64, 'ERROR: invalid input');
        bytes memory data = abi.encode(receiver, tokens);
        _createTransaction(TransactionType.WITHDRAW_ALL, data);
    }

    /// @notice a valid caller can create a transaction to add a new daoMember,
    ///  waiting for getting enough approvals
    /// @dev msg.sender must not have a pending transaction
    /// @param newDaoMember is new daoMember's address
    function createAddDaoMemberTransaction(
        address newDaoMember,
        uint8 newQuorum
    ) external virtual onlyDaoMember notZeroAddress(newDaoMember) canCreateTransaction onlyProxy {
        require(daoMembersCount < 64, 'ERROR: exceeded maximum number of daoMembers');
        require(!isDaoMember[newDaoMember], 'ERROR: provided address is already an daoMember');
        bytes memory data = abi.encode(newDaoMember, newQuorum);
        _createTransaction(TransactionType.ADD_DAO_MEMBER, data);
    }

    /// @notice a valid caller can create a transaction to delete an daoMember,
    /// waiting for getting enough approvals
    /// @dev msg.sender must not have a pending transaction
    /// @param daoMember is daoMember's address
    function createDeleteDaoMemberTransaction(
        address daoMember,
        uint8 newQuorum
    ) external virtual onlyDaoMember notZeroAddress(daoMember) canCreateTransaction onlyProxy {
        require(isDaoMember[daoMember], 'ERROR: provided address is not a DAO member');
        bytes memory data = abi.encode(daoMember, newQuorum);
        _createTransaction(TransactionType.DELETE_DAO_MEMBER, data);
    }

    /// @notice a valid caller can create a transaction to update the quorum,
    /// waiting for getting enough approvals
    /// @dev new value should be less than or equal to the number of
    /// daoMember count `daoMembersCount`
    /// @param newValue new quorum value
    function createUpdateQuorumTransaction(
        uint8 newValue
    ) external virtual onlyDaoMember canCreateTransaction onlyProxy {
        require(int8(newValue) != quorum && newValue <= daoMembersCount, 'ERROR: invalid input');
        bytes memory data = abi.encode(newValue);
        _createTransaction(TransactionType.UPDATE_QUORUM, data);
    }

    /// @notice a valid caller can create a transaction to upgrade this
    /// contract, waiting for getting enough approvals
    /// @dev be careful with the address to be accurate. Upgrading to
    /// this address is irreversible
    /// @param impl new implementation's deployed address
    function createUpgradeDaoMultiSigTransaction(
        address impl
    ) external virtual onlyDaoMember notZeroAddress(impl) canCreateTransaction onlyProxy {
        bytes memory data = abi.encode(impl);
        _createTransaction(TransactionType.UPGRADE_DAO_MULTISIG, data);
    }

    /// @notice a valid caller can create a transaction to re-set the
    /// maximum fee in swap engine contract, waiting for getting enough approvals
    /// @dev be careful don't include any spaces in the functionSignature
    /// @param target swap engine's contract address
    /// @param functionSignature external contract's function signature
    /// @param value new fee value to set
    function createSetSwapperFeeTransaction(
        address target,
        string memory functionSignature,
        uint16 value
    ) external virtual onlyDaoMember notZeroAddress(target) onlyProxy {
        bytes memory data = abi.encode(target, functionSignature, value);
        _createTransaction(TransactionType.SET_SWAPPER_FEE, data);
    }

    /// @notice a valid caller can create a transaction to re-set the
    /// maximum fee in swap engine contract, waiting for getting enough approvals
    /// @dev be careful don't include any spaces in the functionSignature
    /// @param target swap engine's contract address
    /// @param functionSignature external contract's function signature
    /// @param proposedAdmin new admins's address
    function createProposeSwapperAdminTransaction(
        address target,
        string memory functionSignature,
        address proposedAdmin
    ) external virtual onlyDaoMember notZeroAddress(target) notZeroAddress(proposedAdmin) onlyProxy {
        bytes memory data = abi.encode(target, functionSignature, proposedAdmin);
        _createTransaction(TransactionType.PROPOSE_SWAPPER_ADMIN, data);
    }

    /// @notice a valid caller can create a transaction to re-set the
    /// maximum fee in swap engine contract, waiting for getting enough approvals
    /// @dev be careful don't include any spaces in the functionSignature
    /// @param target swap engine's contract address
    /// @param functionSignature external contract's function signature
    function createAcceptSwapperAdminTransaction(
        address target,
        string memory functionSignature
    ) external virtual onlyDaoMember notZeroAddress(target) onlyProxy {
        bytes memory data = abi.encode(target, functionSignature);
        _createTransaction(TransactionType.ACCEPT_SWAPPER_ADMIN, data);
    }

    /// @notice a valid caller can create a transaction to pause swap engine
    /// contract, waiting for getting enough approvals
    /// @dev be careful don't include any spaces in the functionSignature
    /// @param target swap engine's contract address
    /// @param functionSignature external contract's function signature
    function createUnpauseSwapperTransaction(
        address target,
        string memory functionSignature
    ) external virtual onlyDaoMember notZeroAddress(target) onlyProxy {
        bytes memory data = abi.encode(target, functionSignature);
        _createTransaction(TransactionType.UNPAUSE_SWAPPER, data);
    }

    /// @notice a valid caller can approve a pending transaction
    /// @dev each address can approve a transaction once. The creator of the
    /// transaction can't approve it (already approved)
    /// @param txId Id of the transaction to approve
    function approveTransaction(
        uint256 txId
    ) external virtual onlyDaoMember onlyProxy isValidPendingTx(txId) returns (bool) {
        require(txApprovalByDaoMember[msg.sender][txId] != 1, 'ERROR: approved before');
        Transaction storage transaction = transactions[txId];
        transaction.approvals = ++transaction.approvals - txApprovalByDaoMember[msg.sender][txId];
        txApprovalByDaoMember[msg.sender][txId] = 1;
        if (transaction.approvals - quorum == 0) {
            return _executeTransaction(txId, transaction);
        }
        emit TransactionApproved(msg.sender, txId);
        return true;
    }

    /// @notice a valid caller can disapprove a pending transaction
    /// @dev each address can approve a transaction once. The creator of the
    /// transaction can't approve it (already approved)
    /// @param txId Id of the transaction to approve
    function disapproveTransaction(
        uint256 txId
    ) external virtual onlyDaoMember onlyProxy isValidPendingTx(txId) returns (bool) {
        require(txApprovalByDaoMember[msg.sender][txId] != -1, 'ERROR: disapproved before');
        Transaction storage transaction = transactions[txId];
        transaction.approvals = --transaction.approvals - txApprovalByDaoMember[msg.sender][txId];
        txApprovalByDaoMember[msg.sender][txId] = -1;
        if (transaction.approvals + quorum == 0) {
            transaction.status = TransactionStatus.REJECTED;
            _removeFromPendingTransactions(txId);
        }
        emit TransactionDisapproved(msg.sender, txId);
        return true;
    }

    /// @notice a valid caller can disapprove a pending transaction, waiting
    ///  for getting enough approvals
    /// @dev each address can approve a transaction once. The creator of the
    ///  transaction can't disapprove it
    /// @param txId Id of the transaction to disapprove
    function revokeApproval(
        uint256 txId
    ) external virtual onlyDaoMember onlyProxy isValidPendingTx(txId) returns (bool) {
        require(txApprovalByDaoMember[msg.sender][txId] == 1, 'ERROR: no approvals yet');
        Transaction storage transaction = transactions[txId];
        transaction.approvals -= txApprovalByDaoMember[msg.sender][txId];
        txApprovalByDaoMember[msg.sender][txId] = 0;
        emit ApprovalRevoked(msg.sender, txId);
        return true;
    }

    /// @notice a valid caller can disapprove a pending transaction, waiting
    ///  for getting enough approvals
    /// @dev each address can approve a transaction once. The creator of the
    ///  transaction can't disapprove it
    /// @param txId Id of the transaction to disapprove
    function revokeDisApproval(
        uint256 txId
    ) external virtual onlyDaoMember onlyProxy isValidPendingTx(txId) returns (bool) {
        require(txApprovalByDaoMember[msg.sender][txId] == -1, 'ERROR: no disApprovals yet');
        Transaction storage transaction = transactions[txId];
        transaction.approvals -= txApprovalByDaoMember[msg.sender][txId];
        txApprovalByDaoMember[msg.sender][txId] = 0;
        emit DisApprovalRevoked(msg.sender, txId);
        return true;
    }

    /// @notice creator of the transaction can revoke it (drops the transaction from pending)
    /// @dev just the creator of the transaction can revoke it
    /// @param txId Id of the transaction to revoke
    function revokeTransaction(uint256 txId) external virtual onlyProxy isValidPendingTx(txId) returns (bool) {
        Transaction storage _transaction = transactions[txId];
        require(msg.sender == _transaction.from, 'ERROR: invalid caller');
        _transaction.status = TransactionStatus.REVOKED;
        pendingTransactionsByDaoMember[_transaction.from]--;
        _removeFromPendingTransactions(txId);
        emit TransactionRevoked(msg.sender, txId);
        return true;
    }

    /// @notice some pending transactions might be invalid due to expiry
    /// this function runs periodically to remove invalid pending transactions
    function cleanUp() external virtual onlyDaoMember onlyProxy {
        uint8 pendingTxsCount = uint8(pendingTransactions.length);
        for (uint8 i = 1; i - 1 < pendingTxsCount; i++) {
            uint256 txId = pendingTransactions[i - 1];
            Transaction memory transaction = transactions[txId];
            if (transaction.validUntil < block.timestamp) {
                transaction.status = TransactionStatus.EXPIRED;
                pendingTransactions[i - 1] = pendingTransactions[pendingTxsCount - 1];
                pendingTransactionsByDaoMember[transaction.from]--;
                pendingTransactions.pop();
                pendingTxsCount--;
                i--;
            }
        }
    }

    // returns pending transactions filter by none, approved and disapproved
    function getPendingTransactions(
        Filter filter,
        address DAOmember
    ) external view virtual onlyProxy returns (PendingTx[] memory, uint8 total) {
        PendingTx[] memory txs = new PendingTx[](pendingTransactions.length);
        uint256[] memory _pendingTxs = pendingTransactions;
        for (uint8 i = 0; i < _pendingTxs.length; i++) {
            uint256 txId = _pendingTxs[i];
            Transaction memory transaction = transactions[txId];
            if (transaction.validUntil > block.timestamp) {
                if (
                    (filter == Filter.APPROVED && txApprovalByDaoMember[DAOmember][txId] != 1) ||
                    (filter == Filter.DISAPPROVED && txApprovalByDaoMember[DAOmember][txId] != -1)
                ) {
                    continue;
                }

                txs[total].id = _pendingTxs[i];
                txs[total].from = transaction.from;
                txs[total].txType = transaction.txType;
                txs[total].vote = txApprovalByDaoMember[DAOmember][txId];
                txs[total].approvals = transaction.approvals;
                txs[total].validUntil = transaction.validUntil;
                txs[total].data = transaction.data;
                total++;
            }
        }
        return (txs, total);
    }

    /// @notice returns the balance of each asset transferred to the address of this contract
    /// @dev provide a list of ERC20 token addresses as an input (up to 256 item each call)
    /// @param tokens list of token addresses
    /// @return amounts list of return value of each call in the order of provided addresses
    function getBalanceOfAssets(
        address[] memory tokens
    ) public view virtual onlyDaoMember onlyProxy returns (uint256[] memory) {
        address _address = address(this);
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            (bool success, bytes memory data) = address(tokens[i]).staticcall(
                abi.encodeWithSignature('balanceOf(address)', _address)
            );
            if (!success) {
                revert ERC20CallReverted(tokens[i]);
            }
            amounts[i] = abi.decode(data, (uint256));
        }
        return amounts;
    }

    function _createTransaction(TransactionType txType, bytes memory data) internal {
        uint256 txId = ++transactionsCount;
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.txType = txType;
        // 259200 = 3 * 24 * 60 * 60
        transaction.validUntil = uint64(block.timestamp) + 259200;
        transaction.data = data;
        unchecked {
            transaction.approvals++;
            // map txId to creator to track daoMember's pending transaction
            pendingTransactionsByDaoMember[msg.sender]++;
        }
        // add create transaction to mapping
        transactions[txId] = transaction;
        // creator of the transaction is one of the the daoMember too
        txApprovalByDaoMember[msg.sender][txId] = 1;
        // add transaction id to pending list
        pendingTransactions.push(txId);
        emit TransactionCreated(msg.sender, txId);
    }

    /// @notice creator of the transaction can execute the already
    /// created transaction, after getting enough approvals
    /// @dev just the creator of the transaction can execute it
    /// @param txId Id of the transaction to execute
    function _executeTransaction(
        uint256 txId,
        Transaction storage _transaction
    ) internal virtual isValidPendingTx(txId) returns (bool) {
        if (!isDaoMember[_transaction.from]) {
            revert('ERROR: transaction creator is not a DaoMember anymore');
        }

        _transaction.status = TransactionStatus.EXECUTED;
        TransactionType txType = _transaction.txType;

        // execute Withdraw transaction
        if (txType == TransactionType.WITHDRAW) {
            (address payable receiver, address[] memory tokens, uint256[] memory amounts) = abi.decode(
                _transaction.data,
                (address, address[], uint256[])
            );
            _withdraw(receiver, tokens, amounts);
            return _afterExecution(txId);
        }

        // execute WITHDRAW_ALL transaction
        if (txType == TransactionType.WITHDRAW_ALL) {
            (address payable receiver, address[] memory tokens) = abi.decode(_transaction.data, (address, address[]));
            _withdrawAll(receiver, tokens);
            return _afterExecution(txId);
        }

        // execute SET_SWAPPER_FEE transaction
        if (txType == TransactionType.SET_SWAPPER_FEE) {
            (address callee, string memory functionSignature, uint16 fee) = abi.decode(
                _transaction.data,
                (address, string, uint16)
            );
            _setSwapFee(callee, functionSignature, fee);
            return _afterExecution(txId);
        }

        // execute PROPOSE_SWAPPER_ADMIN transaction
        if (txType == TransactionType.PROPOSE_SWAPPER_ADMIN) {
            (address callee, string memory functionSignature, address proposedAdmin) = abi.decode(
                _transaction.data,
                (address, string, address)
            );
            _proposeSwapperAdmin(callee, functionSignature, proposedAdmin);
            return _afterExecution(txId);
        }

        // execute ACCEPT_SWAPPER_ADMIN transaction
        if (txType == TransactionType.ACCEPT_SWAPPER_ADMIN) {
            (address callee, string memory functionSignature) = abi.decode(_transaction.data, (address, string));
            _acceptSwapperAdmin(callee, functionSignature);
            return _afterExecution(txId);
        }

        // execute UNPAUSE_SWAPPER transaction
        if (txType == TransactionType.UNPAUSE_SWAPPER) {
            (address callee, string memory functionSignature) = abi.decode(_transaction.data, (address, string));
            _unpauseSwapper(callee, functionSignature);
            return _afterExecution(txId);
        }

        // execute ADD_DAO_MEMBER transaction
        if (txType == TransactionType.ADD_DAO_MEMBER) {
            (address newDaoMember, uint8 newQuorum) = abi.decode(_transaction.data, (address, uint8));
            _addDaoMember(newDaoMember, newQuorum);
            return _afterExecution(txId);
        }

        // execute DELETE_DAO_MEMBER transaction
        if (txType == TransactionType.DELETE_DAO_MEMBER) {
            (address daoMember, uint8 newQuorum) = abi.decode(_transaction.data, (address, uint8));
            _deleteDaoMember(daoMember, newQuorum);
            return _afterExecution(txId);
        }

        // execute UPDATE_QUORUM transaction
        if (txType == TransactionType.UPDATE_QUORUM) {
            uint8 newValue = abi.decode(_transaction.data, (uint8));
            _updateQuorum(newValue);
            return _afterExecution(txId);
        }

        // execute UPGRADE_DAO_MULTISIG transaction
        if (txType == TransactionType.UPGRADE_DAO_MULTISIG) {
            address newImpl = abi.decode(_transaction.data, (address));
            _upgrade(newImpl);
            return _afterExecution(txId);
        }

        revert('ERROR: tx type not found');
    }

    function _afterExecution(uint256 txId) internal virtual returns (bool) {
        pendingTransactionsByDaoMember[transactions[txId].from]--;
        _removeFromPendingTransactions(txId);
        emit TransactionExecuted(msg.sender, txId);
        return true;
    }

    // we don't use safeTransfer as we know which tokens we are interacting with
    // we are considering tokens like USDT which aren't fully compatible with ERC20 standard
    function _withdraw(address payable receiver, address[] memory tokens, uint256[] memory amounts) internal virtual {
        uint256 EthBalance = address(this).balance;
        for (uint8 i = 0; i < tokens.length; i++) {
            if ((tokens[i] == address(0)) && (EthBalance > 0)) {
                (bool EthTransferSuccess, ) = receiver.call{value: EthBalance}('');
                emit EthTransferStatus(EthTransferSuccess);
            }
            (bool success, ) = address(tokens[i]).call(
                abi.encodeWithSelector(IERC20(tokens[i]).transfer.selector, receiver, amounts[i])
            );
            if (!success) {
                emit ERC20UnsuccessfulTransfer(tokens[i]);
            }
        }
    }

    function _withdrawAll(address payable receiver, address[] memory tokens) internal virtual nonReentrant {
        uint256[] memory amounts = getBalanceOfAssets(tokens);
        _withdraw(receiver, tokens, amounts);
    }

    function _addDaoMember(address newDaoMember, uint8 newQuorum) internal virtual {
        require(daoMembersCount < 64, 'ERROR: exceeded maximum number of daoMembers');
        daoMembersCount++;
        isDaoMember[newDaoMember] = true;
        _updateQuorum(newQuorum);
    }

    function _deleteDaoMember(address daoMember, uint8 newQuorum) internal virtual {
        daoMembersCount--;
        delete isDaoMember[daoMember];

        for (uint8 i = 1; i - 1 < pendingTransactions.length; i++) {
            Transaction memory transaction = transactions[pendingTransactions[i - 1]];
            if (transaction.from == daoMember) {
                pendingTransactions[i - 1] = pendingTransactions[pendingTransactions.length - 1];
                pendingTransactions.pop();
                i--;
            } else {
                int8 daoMemberApproval = txApprovalByDaoMember[daoMember][pendingTransactions[i - 1]];
                if (daoMemberApproval != 0) {
                    transaction.approvals -= daoMemberApproval;
                    txApprovalByDaoMember[daoMember][pendingTransactions[i - 1]] = 0;
                }
            }
        }
        delete pendingTransactionsByDaoMember[daoMember];
        _updateQuorum(newQuorum);
    }

    function _updateQuorum(uint8 newValue) internal virtual {
        require(newValue <= daoMembersCount, 'ERROR: invalid input');
        quorum = int8(newValue);
    }

    function _upgrade(address newImpl) internal virtual {
        newImplAddress = newImpl;
    }

    function _setSwapFee(address callee, string memory functionSignature, uint256 fee) internal virtual {
        (bool success, ) = callee.call(abi.encodeWithSignature(functionSignature, fee));
        require(success, 'ERROR: external call failed');
    }

    function _proposeSwapperAdmin(
        address callee,
        string memory functionSignature,
        address proposedAdmin
    ) internal virtual {
        (bool success, ) = callee.call(abi.encodeWithSignature(functionSignature, proposedAdmin));
        require(success, 'ERROR: external call failed');
    }

    function _acceptSwapperAdmin(address callee, string memory functionSignature) internal virtual {
        (bool success, ) = callee.call(abi.encodeWithSignature(functionSignature));
        require(success, 'ERROR: external call failed');
    }

    function _unpauseSwapper(address callee, string memory functionSignature) internal virtual {
        (bool success, ) = callee.call(abi.encodeWithSignature(functionSignature));
        require(success, 'ERROR: external call failed');
    }

    /// @notice remove an item from list by swapping it with the last item
    /// @param txId the transaction id to be removed from pending transaction's list
    function _removeFromPendingTransactions(uint256 txId) internal virtual {
        uint256 pendingTxsCount = pendingTransactions.length;
        for (uint8 i = 0; i < pendingTxsCount; i++) {
            if (pendingTransactions[i] == txId) {
                pendingTransactions[i] = pendingTransactions[pendingTxsCount - 1];
                pendingTransactions.pop();
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyDaoMember {
        require(newImplAddress != address(0), 'ERROR: upgrade to zero address');
        require(newImplAddress == newImplementation, "ERROR: implementation address don't match with preset address");
    }
}