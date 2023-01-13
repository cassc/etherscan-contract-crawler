// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "hardhat/console.sol";

interface Factory {
    function onOwnerAdded(address owner) external;

    function onOwnerRemoved(address owner) external;
}

contract MultiSignWalletV1 is Initializable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Transaction {
        bytes data;
        uint256 nonce;
        address creator;
        uint256 created;
    }

    struct TransactionWithIndex {
        bytes32 index;
        Transaction transaction;
    }

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event QuorumSet(uint256 quorum);
    event TokenSent(address indexed token, address indexed to, uint256 amount);
    event ETHSent(address indexed to, uint256 amount);
    event TransactionAdded(address indexed creator, bytes32 indexed tid);
    event TransactionExecuted(address indexed executor, bytes32 indexed tid);
    event TransactionRemoved(address indexed remover, bytes32 indexed tid);

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256('ExecuteTransaction(bytes32 tid)')
    bytes32 public constant EXECUTE_TRANSACTION_TYPEHASH =
        0x5cec503fa9385fc412d4c741218e3ead649ba722ca4a8c8fd63a7631f8a60af2;
    // keccak256('RemoveTransaction(bytes32 tid)')
    bytes32 public constant REMOVE_TRANSACTION_TYPEHASH =
        0xcebd725ed666909bcef13b8d0c05d8682f3b2fa660cd24b5f44031ced164576a;

    uint256 public nonce;
    uint256 public quorum;
    Factory public factory;
    mapping(bytes32 => Transaction) public transaction;

    EnumerableSet.Bytes32Set private _transactions;
    EnumerableSet.AddressSet private _owners;

    modifier selfOnly() {
        console.log(msg.sender);
        require(
            msg.sender == address(this),
            "Wallet(selfOnly): can not be called directly"
        );
        _;
    }

    modifier ownerOnly() {
        require(_owners.contains(msg.sender), "Wallet(ownerOnly): forbidden");
        _;
    }

    modifier once(bytes32 tid) {
        require(
            _transactions.contains(tid),
            "Wallet(once): transaction not found"
        );
        _;
        _transactions.remove(tid);
    }

    function init(address[] memory owners, uint256 _quorum) public initializer {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("MultiSignWallet"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
        factory = Factory(msg.sender);

        for (uint256 i; i < owners.length; i++) {
            Address.functionCall(
                address(this),
                abi.encodeCall(this.addOwner, (owners[i]))
            );
        }
        Address.functionCall(
            address(this),
            abi.encodeCall(this.setQuorum, (_quorum))
        );
    }

    function addOwner(address owner) public selfOnly {
        _owners.add(owner);

        factory.onOwnerAdded(owner);
        emit OwnerAdded(owner);
    }

    function removeOwner(address owner) public selfOnly {
        _owners.remove(owner);
        require(
            _owners.length() >= quorum,
            "Wallet(removeOwner): number of owners cannot be less than quorum"
        );

        factory.onOwnerRemoved(owner);
        emit OwnerRemoved(owner);
    }

    function setQuorum(uint256 _quorum) public selfOnly {
        require(_quorum > 0, "Wallet(setQuorum): zero quorum");
        require(
            _quorum <= _owners.length(),
            "Wallet(setQuorum): quorum can not be greater than number of owners"
        );
        quorum = _quorum;

        emit QuorumSet(_quorum);
    }

    function send(
        address token,
        address to,
        uint256 amount
    ) public selfOnly nonReentrant {
        IERC20(token).transfer(to, amount);

        emit TokenSent(token, to, amount);
    }

    function sendETH(address payable to, uint256 amount)
        public
        selfOnly
        nonReentrant
    {
        Address.sendValue(to, amount);

        emit ETHSent(to, amount);
    }

    receive() external payable {}

    function addTransaction(bytes calldata data) external ownerOnly {
        Transaction memory trx = Transaction(
            data,
            nonce++,
            msg.sender,
            block.timestamp
        );
        bytes32 tid = keccak256(abi.encode(trx.nonce, trx.data));

        transaction[tid] = trx;
        _transactions.add(tid);

        emit TransactionAdded(msg.sender, tid);
    }

    function executeTransaction(bytes32 tid, bytes[] calldata signatures)
        external
        ownerOnly
        once(tid)
    {
        Transaction memory trx = transaction[tid];
        bytes32 structHash = keccak256(
            abi.encode(EXECUTE_TRANSACTION_TYPEHASH, tid)
        );
        expectAllowed(structHash, signatures, trx, msg.sender);

        Address.functionCall(
            address(this),
            trx.data,
            "Wallet(executeTransaction): call failed"
        );

        emit TransactionExecuted(msg.sender, tid);
    }

    function removeTransaction(bytes32 tid, bytes[] calldata signatures)
        external
        ownerOnly
        once(tid)
    {
        Transaction memory trx = transaction[tid];
        bytes32 structHash = keccak256(
            abi.encode(REMOVE_TRANSACTION_TYPEHASH, tid)
        );
        expectAllowed(structHash, signatures, trx, msg.sender);

        emit TransactionRemoved(msg.sender, tid);
    }

    function getOwners() external view returns (address[] memory owners) {
        owners = new address[](_owners.length());
        for (uint256 i; i < _owners.length(); i++) {
            owners[i] = _owners.at(i);
        }
    }

    function getTransactions()
        external
        view
        returns (TransactionWithIndex[] memory transactions)
    {
        transactions = new TransactionWithIndex[](_transactions.length());
        for (uint256 i; i < _transactions.length(); i++) {
            transactions[i] = TransactionWithIndex(
                _transactions.at(i),
                transaction[_transactions.at(i)]
            );
        }
    }

    function expectAllowed(
        bytes32 structHash,
        bytes[] calldata signatures,
        Transaction memory trx,
        address sender
    ) internal view {
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);

        uint256 confirmations = 1; // creator
        if (trx.created + 30 days < block.timestamp) {
            confirmations = quorum; // creator can execute transaction after 30 days byself
        } else {
            if (trx.creator != msg.sender) {
                confirmations++; // second owner who request execution already signer
            }

            address previousSigner;
            for (uint256 i; i < signatures.length; i++) {
                address signer = ECDSA.recover(digest, signatures[i]);
                if (signer == trx.creator || signer == sender) {
                    continue;
                }
                require(
                    _owners.contains(signer),
                    "Wallet(verifySignatures): not owner"
                );
                require(
                    previousSigner < signer,
                    "Wallet(verifySignatures): not sorted"
                );
                previousSigner = signer;
                confirmations++;
            }
        }

        require(
            confirmations >= quorum,
            "Wallet(verifySignatures): can not reach quorum"
        );
    }
}