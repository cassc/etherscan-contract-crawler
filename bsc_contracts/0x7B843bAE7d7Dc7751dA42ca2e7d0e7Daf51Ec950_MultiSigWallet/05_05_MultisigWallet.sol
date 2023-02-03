// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiSigWallet {

    using SafeERC20 for IERC20;

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed destination,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event RecoverERC20(address tokenAddress, uint256 amount);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;

    struct Transaction {
        address destination;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

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

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "owners required");
        require(
            _threshold > 0 && _threshold <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        threshold = _threshold;
    }

    function submitTransaction(address _destination, bytes memory _data)
        external
        onlyOwner
    {
        uint256 txIndex = transactions.length;
        transactions.push(
            Transaction({
                destination: _destination,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _destination, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        external
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
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= threshold, "cannot execute tx");
        transaction.executed = true;

        (bool success, ) = transaction.destination.call(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        external
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

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external
        view
        returns (
            address destination,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.destination,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function recoverToken(address _tokenAddress,address walletAddress, uint256 amount)
        external
    {
        require(msg.sender == address(this), "only multisig can call");
        require(walletAddress != address(0), "Null address");
        require(amount <= IERC20(_tokenAddress).balanceOf(address(this)), "Insufficient amount");
        IERC20(_tokenAddress).safeTransfer(
            walletAddress,
            amount
        );
    }

    function recoverETH(address walletAddress)
        external
        payable
    {
        require(msg.sender == address(this), "only multisig can call");
        require(walletAddress != address(0), "Null address");
        uint256 balance = address(this).balance;
        payable(walletAddress).transfer(balance);
    }
    
}