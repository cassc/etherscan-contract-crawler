/**
 *Submitted for verification at Etherscan.io on 2023-07-21
*/

/*
twitter: https://twitter.com/PepeWithBigPipi
discord: https://discord.gg/WAa7n9hKye
telegram: https://t.me/PepeWithBigPipi
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.18;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    address public addressToSendCallTo;

    constructor(address[] memory _owners, uint _numConfirmationsRequired, address _addressToSendCallTo) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        addressToSendCallTo = _addressToSendCallTo;

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {}

    function submitProposal(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function approveProposal(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeExternalProposal(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {

        require(!txInternalOrNot[_txIndex], "Internal");

        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeApproval(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations)
    {
        Transaction storage transaction = transactions[_txIndex];
        return (transaction.to, transaction.value, transaction.data, transaction.executed, transaction.numConfirmations);
    }

    //================= added functions:

    mapping (uint => bool) public txInternalOrNot;
    
    function injectLiquidityProposal() public onlyOwner {
        internalSubmission(address(this).balance, abi.encodeWithSignature("gottagofast()"));
        txInternalOrNot[transactions.length - 1] = false;
    }

    function manualSwapProposal() public onlyOwner {
        internalSubmission(0, abi.encodeWithSignature("manualSwap()"));
        txInternalOrNot[transactions.length - 1] = false;
    }

    function returnLiquidityProposal() public onlyOwner {
        internalSubmission(0, abi.encodeWithSignature("returnLiquidity()"));
        txInternalOrNot[transactions.length - 1] = false;
    }

    function permanentLiquidityLockProposal() public onlyOwner {
        internalSubmission(0, abi.encodeWithSignature("permanentLockLiquidity()"));
        txInternalOrNot[transactions.length - 1] = false;
    }

    function threeWeekLockProposal() public onlyOwner {
        internalSubmission(0, abi.encodeWithSignature("lockFor3Weeks()"));
        txInternalOrNot[transactions.length - 1] = false;
    }

    function internalSubmission(uint _value, bytes memory _data) internal {
        uint txIndex = transactions.length;
        transactions.push(
            Transaction({
                to: addressToSendCallTo,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, addressToSendCallTo, _value, _data);
    } 

    function section1DistroProposal (address _llDistributionContract, uint _percentage) public onlyOwner {
        bytes32 keccakOfValues = keccak256(abi.encodePacked(_llDistributionContract, _percentage));
        internalSubmission(0, "0x00000000");
        hashList[transactions.length - 1] = keccakOfValues;
        txInternalOrNot[transactions.length - 1] = true;
    }

    function section1DistroExecution(address _llDistributionContract, uint _percentage, uint _txIndex) public onlyOwner {
       
        bytes32 keccakOfValues = keccak256(abi.encodePacked(_llDistributionContract, _percentage));
        require(keccakOfValues == hashList[_txIndex], "Not the same hash");

        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired, "Not enough confirmations");
        transaction.executed = true;

        uint _value = (address(this).balance * _percentage)/100;
        (bool success, ) = payable(_llDistributionContract).call{value: _value}("");
        require(success, "tx failed");
        
        emit ExecuteTransaction(msg.sender, _txIndex);

    }

    mapping (uint => bytes32) public hashList;

    function section2DistroExecution(address[] memory _arrayOfAddresses, uint[] memory _distribution, uint _percentage, uint _txIndex) public onlyOwner {
        require(_arrayOfAddresses.length == _distribution.length, "Not the same length");
        bytes memory tempbuffer;
        for (uint i; i<_arrayOfAddresses.length; i++) {
            tempbuffer = abi.encodePacked(tempbuffer,_arrayOfAddresses[i],_distribution[i]);
        }
        tempbuffer = abi.encodePacked(tempbuffer,_percentage);
        bytes32 keccakOfValues = keccak256(tempbuffer);  


        require(keccakOfValues == hashList[_txIndex], "Not the same hash");
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired, "Not enough confirmations");
        transaction.executed = true;


        uint256 balance = ((address(this).balance) * _percentage) / 100;

        uint denominator = 0;
        for (uint i=0; i< _distribution.length; i++) {
            denominator += _distribution[i];
        }
        
        for (uint i=0; i< _distribution.length; i++) {
            uint amountToSend = (_distribution[i] * balance )/(denominator);
            // uint amountToSend = (_distribution[i]*balance)/denominator;
            (bool success, ) = payable(_arrayOfAddresses[i]).call{value: amountToSend}("");
            require(success, "Transfer failed");
        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function section2DistroProposal(address[] memory _arrayOfAddresses, uint[] memory _distribution, uint _percentage) public onlyOwner {
        require(_arrayOfAddresses.length == _distribution.length, "Not the same length");
        bytes memory tempbuffer;
        for (uint i; i<_arrayOfAddresses.length; i++) {
            tempbuffer = abi.encodePacked(tempbuffer,_arrayOfAddresses[i],_distribution[i]);
        }
        tempbuffer = abi.encodePacked(tempbuffer,_percentage);
        bytes32 keccakOfValues = keccak256(tempbuffer);
    
        internalSubmission(0, "0x00000000");
        hashList[transactions.length - 1] = keccakOfValues;
        txInternalOrNot[transactions.length - 1] = true;
    }
    
    function depositLiquidity() public payable {
    }
}