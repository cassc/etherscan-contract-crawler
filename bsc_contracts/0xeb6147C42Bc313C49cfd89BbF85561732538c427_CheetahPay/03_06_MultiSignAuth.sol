/*
    MultiSign token class, developed by Kraitor <TG: kraitordev>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract MultiSignAuth {
    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */    
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) internal isOwner;    
    mapping (bytes => uint) public transactionsIds;
    address[] internal owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    constructor(address _owner) {
        isOwner[_owner] = true;
        owners.push(_owner);
        required = 1;
    }

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);

    /*
     *  Modifiers
     */
    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

    modifier onlyOwners() {
        require(isOwner[msg.sender], "!OWNER"); _;
    }

    bool multiSignAuthRan;
    modifier multiSignReq() { 
        require(isOwner[msg.sender], "!OWNER");
        multiSignAuthRan = false; 
        _;
        require(multiSignAuthRan, "This transaction requires multisign"); 
        multiSignAuthRan = false;
    }

    /*
     * Public functions
     */
    /// @dev Sets initial owners and required number of confirmations.
    /// @param _owners List of owners.
    /// @param _required Number of required confirmations.
    function MultiSignOwners(address[] memory _owners, uint _required)
        public
        multiSignReq
        validRequirement(_owners.length, _required)
    {        
        if(multiSign()){
            for (uint i=0; i<owners.length; i++) {
                isOwner[owners[i]] = false;
            }
            for (uint i=0; i<_owners.length; i++) {
                require(_owners[i] != address(0));
                isOwner[_owners[i]] = true;
            }
            owners = _owners;
            required = _required;
        }
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @return Returns transaction ID.
    function addTransaction()
        internal
        returns (uint)
    {
        uint transactionId = transactionCount;
        if(!transactions[transactionsIds[msg.data]].executed && transactions[transactionsIds[msg.data]].destination != address(0))
        {
            transactionId = transactionsIds[msg.data];
        }
        else
        {
            transactions[transactionId] = Transaction({
                destination: address(this),
                value: msg.value,
                data: msg.data,
                executed: false
            });
            transactionsIds[msg.data] = transactionId;
            transactionCount += 1;            
            emit Submission(transactionId);
        }        
        return transactionId;
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        internal
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;        
        emit Confirmation(msg.sender, transactionId);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @return Returns transaction ID.
    function submitTransaction()
        internal
        returns (uint)
    {
        uint transactionId = addTransaction();        
        require(!transactions[transactionId].executed, "Transaction already executed");        
        confirmTransaction(transactionId);
        return transactionId;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @return Returns the transaction status
    function multiSign()
        internal
        returns (bool)
    {
        multiSignAuthRan = true;
        uint _transactionId = submitTransaction();
        bool _execute = isConfirmed(_transactionId);
        transactions[_transactionId].executed = _execute;
        return _execute;
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId) 
        public view 
        returns (uint)
    {
        uint count;
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
        return count;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public view
        returns (uint)
    {
        uint count;
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
        return count;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public view
        returns (address[] memory)
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public view
        returns (address[] memory)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        address[] memory _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];

        return _confirmations;
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public view
        returns (uint[] memory)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        uint[] memory _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];

        return _transactionIds;
    }
}