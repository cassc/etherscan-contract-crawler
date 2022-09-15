pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { AddressArrayUtils } from "./lib/AddressArrayUtils.sol";

contract SOFIMultiSigWallet {
    using AddressArrayUtils for address[];

    uint constant public MAX_OWNER_COUNT = 10;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
         require(msg.sender == address(this), "only from wallet");
          _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "owner does exist");
         _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "owner does not exist");
         _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner], "not confirmed");
         _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner], "confirmed already");
         _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, "executed already");
         _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0, "invalid requirement");
         _;
    }

    
    receive ()
        external
        payable
    {
        if (msg.value > 0)
           emit Deposit(msg.sender, msg.value);
    }

    
    constructor(address[] memory _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }


    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

   
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        owners = owners.remove(owner);

        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }


    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    
    function submitTransaction(address destination, uint value, bytes memory data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction memory tx = transactions[transactionId];
            // solium-disable-next-line security/no-call-value
            (bool success, bytes memory returnData) = tx.destination.call{value: tx.value}(tx.data);
            require(success, "executeTransaction: Transaction execution reverted.");

            if (success) {
                emit Execution(transactionId);
                tx.executed = true;
            }
            else {
                emit ExecutionFailure(transactionId);
                tx.executed = false;
            }
    }
    }

    
    function isConfirmed(uint transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }
    

    function addTransaction(address destination, uint value, bytes memory data)
        internal
        returns (uint transactionId)
    {
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
    

    function getConfirmationCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }
}