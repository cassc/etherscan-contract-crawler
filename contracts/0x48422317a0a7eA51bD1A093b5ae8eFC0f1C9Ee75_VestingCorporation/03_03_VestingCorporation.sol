// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../erc20/IERC20.sol";
import "./MultiSignReceiverChangeTx.sol";

contract VestingCorporation is MultiSignReceiverChangeTx {
    uint8 public constant decimals = 18;

    struct Transaction {
        uint256 value;
        uint256 expired;
        bool executed;
    }

    Transaction[] public transactions;
    IERC20 public token;
    address public owner;
    address public receiver = 0xa72C2640542d5d9882B0D70A59fc7cF19221ADA0;
    address[] public signers = [
        0xd5e7F7f96109Ea5d86ea58f8cEE67505d414769b,
        0xFB643159fB9d6B4064D0EC3a5048503deC72cAf2,
        0xaFdA9e685A401E8B791ceD4F13a3aB4Ed0ff12e3,
        0x0377DA3EA8c9b56E4428727FeF417eFf12950e3f,
        0x1bE9e3393617B74E3A92487a86EE2d2D4De0BfaA
    ];
    // 36 Months Timestamp
    uint256[] public vestingTimestamp = [
        1709251200,
        1711929600,
        1714521600,
        1717200000,
        1719792000,
        1722470400,
        1725148800,
        1727740800,
        1730419200,
        1733011200,
        1735689600,
        1738368000,
        1740787200,
        1743465600,
        1746057600,
        1748736000,
        1751328000,
        1754006400,
        1756684800,
        1759276800,
        1761955200,
        1764547200,
        1767225600,
        1769904000,
        1772323200,
        1775001600,
        1777593600,
        1780272000,
        1782864000,
        1785542400,
        1788220800,
        1790812800,
        1793491200,
        1796083200,
        1798761600,
        1801440000
    ];
    mapping(address => bool) public isSigner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not signer");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "TX does not exist");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "TX already executed");
        _;
    }

    constructor() MultiSignReceiverChangeTx(signers, signers.length) {
        owner = msg.sender;

        for (uint256 i; i < signers.length; i++) {
            address signer = signers[i];
            require(signer != address(0), "Invalid signer");
            require(!isSigner[signer], "Signer is not unique");

            isSigner[signer] = true;
        }

        // 36 Months = 120,000,000
        // 3,333,333 * 35 = 116,666,655
        for (uint256 i = 0; i < vestingTimestamp.length - 1; i++) {
            transactions.push(
                Transaction({
                    value: 3333333 * 10**decimals,
                    expired: vestingTimestamp[i],
                    executed: false
                })
            );
        }

        // 120,000,000 - 116,666,655 = 3,333,345
        transactions.push(
            Transaction({
                value: 3333345 * 10**decimals,
                expired: vestingTimestamp[vestingTimestamp.length - 1],
                executed: false
            })
        );
    }

    function setTokenAddress(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }

    function withdraw(uint256 _txId)
        external
        onlySigner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        require(
            block.timestamp >= transaction.expired,
            "Tokens have not been unlocked"
        );
        require(
            getBalance() >= transaction.value,
            "Not enough for the balance."
        );

        token.transfer(receiver, transaction.value);
        transaction.executed = true;
    }

    function rcTxExecute(uint256 _txId)
        public
        override
        onlyRcTxSigner
        rcTxExists(_txId)
        rcTxNotExecuted(_txId)
    {
        require(
            getRcTxApprovalCount(_txId) >= rcTxRequired,
            "The required number of approvals is insufficient"
        );

        RcTransaction storage rcTransaction = rcTransactions[_txId];
        receiver = rcTransaction.receiver;
        rcTransaction.executed = true;
        emit RcTxExecute(_txId);
    }
}