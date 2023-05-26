///SPDX-License-Identifier: UNLICENSED

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.13;

contract MultiSigWallet {


  using SafeERC20 for IERC20;

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed token,
        address user,
        uint256 amount
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    address[] public requiredOwners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    bool public init;


    struct Transaction {
        address token;
        address user;
        uint256 amount;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, bool[] memory _requiredOwner, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(_owners.length == _requiredOwner.length, "owner list and required list length");
        require(
            _numConfirmationsRequired > 0 &&
            _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );


        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            bool ownerRequired = _requiredOwner[i];
            if(ownerRequired){
                requiredOwners.push(owner);
            }

            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        require(_numConfirmationsRequired >= requiredOwners.length, "numConfirmationsRequired >= requiredOwners.length");
    }

    function initialise (address _tokenToApprove, address _userToApprove) public onlyOwner {
        require(!init, "Already initialised");
        IERC20(_tokenToApprove).safeApprove(_userToApprove, 2**256 - 1); //approve max
        init = true;
    }

    function submitTransaction(
        address _token,
        address _user,
        uint256 _amount
    ) public onlyOwner returns (uint256 txIndex) {
        txIndex = transactions.length;

        transactions.push(
            Transaction({
                token: _token,
                user: _user,
                amount: _amount,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _token, _user, _amount);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Not enough confirmations"
        );

        for(uint256 i = 0; i < requiredOwners.length; i++ ){
            require(isConfirmed[_txIndex][requiredOwners[i]], "required owner not signed");
        }

        transaction.executed = true;

        emit ExecuteTransaction(msg.sender, _txIndex);
        
        IERC20(transaction.token).safeTransfer(
            transaction.user,
            transaction.amount
        );

    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }


    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address token,
            address user,
            uint256 amount,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.token,
            transaction.user,
            transaction.amount,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}