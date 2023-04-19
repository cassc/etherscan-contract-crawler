pragma solidity 0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';

contract MultiSigWallet is Ownable {
    uint256 public constant MAX_member_COUNT = 20;

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event MemberAddition(address indexed member);
    event MemberRemoval(address indexed member);
    event RequirementChange(uint256 required);

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isMember;
    address[] public members;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this), 'only for Wallet call');
        _;
    }

    modifier memberDoesNotExist(address member) {
        require(!isMember[member], 'member exists');
        _;
    }

    modifier memberExists(address member) {
        require(isMember[member], 'member not exist');
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            'transaction not exist'
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address member) {
        require(
            confirmations[transactionId][member],
            'transaction not comfired'
        );
        _;
    }

    modifier notConfirmed(uint256 transactionId, address member) {
        require(!confirmations[transactionId][member], 'transaction comfired');
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, 'transaction executed');
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), 'address is null');
        _;
    }

    modifier validRequirement(uint256 memberCount, uint256 _required) {
        require(
            memberCount <= MAX_member_COUNT &&
                _required <= memberCount &&
                _required != 0 &&
                memberCount != 0,
            'error'
        );
        _;
    }

    constructor(
        address[] memory _members,
        uint256 _required
    ) validRequirement(_members.length, _required) {
        for (uint256 i = 0; i < _members.length; i++) {
            require(_members[i] != address(0), 'address is null');
            isMember[_members[i]] = true;
        }
        members = _members;
        required = _required;
    }

    /// @dev Allows to add a new member. Transaction has to be sent by wallet.
    /// @param member Address of new member.
    function addMember(
        address member
    )
        public
        onlyWallet
        memberDoesNotExist(member)
        notNull(member)
        validRequirement(members.length + 1, required)
    {
        isMember[member] = true;
        members.push(member);
        emit MemberAddition(member);
    }

    /// @dev Allows to remove an member. Transaction has to be sent by wallet.
    /// @param member Address of member.
    function removeMember(
        address member
    ) public onlyWallet memberExists(member) {
        isMember[member] = false;
        for (uint256 i = 0; i < members.length - 1; i++)
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                break;
            }
        members.pop();
        if (required > members.length) changeRequirement(members.length);
        emit MemberRemoval(member);
    }

    // /// @dev Allows to replace an member with a new member. Transaction has to be sent by wallet.
    // /// @param member Address of member to be replaced.
    // /// @param member Address of new member.
    // function replaceMember(address member, address newMember)
    //     public
    //     onlyWallet
    //     memberExists(member)
    //     memberDoesNotExist(newMember)
    // {
    //     for (uint256 i = 0; i < members.length; i++)
    //         if (members[i] == member) {
    //             members[i] = newMember;
    //             break;
    //         }
    //     isMember[member] = false;
    //     isMember[newMember] = true;
    //     emit MemberRemoval(member);
    //     emit MemberAddition(newMember);
    // }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(
        uint256 _required
    ) public onlyWallet validRequirement(members.length, _required) {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an member to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data);
        // confirmTransaction(transactionId);
    }

    /// @dev Allows an member to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(
        uint256 transactionId
    )
        public
        memberExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an member to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(
        uint256 transactionId
    )
        public
        memberExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(
        uint256 transactionId
    ) public notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage transaction = transactions[transactionId];
            transaction.executed = true;
            (bool success, ) = transaction.destination.call{
                value: transaction.value
            }(transaction.data);
            if (success) emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                transaction.executed = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (confirmations[transactionId][members[i]]) count += 1;
            if (count == required) return true;
        }
        return false;
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal notNull(destination) returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(
        uint256 transactionId
    ) public view returns (uint256 count) {
        for (uint256 i = 0; i < members.length; i++)
            if (confirmations[transactionId][members[i]]) count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(
        bool pending,
        bool executed
    ) public view returns (uint256 count) {
        for (uint256 i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) count += 1;
    }

    /// @dev Returns list of members.
    /// @return List of member addresses.
    function getmembers() public view returns (address[] memory) {
        return members;
    }

    /// @dev Returns array with member addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of member addresses.
    function getConfirmations(
        uint256 transactionId
    ) public view returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](members.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < members.length; i++)
            if (confirmations[transactionId][members[i]]) {
                confirmationsTemp[count] = members[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }

    // function getTransactionIds(
    //     uint256 from,
    //     uint256 to,
    //     bool pending,
    //     bool executed
    // ) public view returns (uint256[] memory _transactionIds) {
    //     uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
    //     uint256 count = 0;
    //     uint256 i;
    //     for (i = 0; i < transactionCount; i++)
    //         if (
    //             (pending && !transactions[i].executed) ||
    //             (executed && transactions[i].executed)
    //         ) {
    //             transactionIdsTemp[count] = i;
    //             count += 1;
    //         }
    //     _transactionIds = new uint256[](to - from);
    //     for (i = from; i < to; i++)
    //         _transactionIds[i - from] = transactionIdsTemp[i];
    // }
}