//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BridgeAssist
 * @author gotbit
 */

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import 'hardhat/console.sol';

contract BridgeAssist is AccessControl, Pausable {
    bytes32 public constant RELAYER_ROLE = keccak256('RELAYER_ROLE');

    struct Transaction {
        address user;
        uint256 timestamp;
        uint256 amount;
        uint256 from;
        uint256 to;
        uint256 nonce;
    }

    IERC20 public immutable token;

    address public feeWallet;
    uint256 public limitPerSend;
    uint256 public nonce;
    uint256 public fee;

    mapping(address => Transaction[]) public transactions;
    mapping(bytes32 => bool) public fulfilled;

    event SentTokens(
        uint256 indexed timestamp,
        address indexed user,
        uint256 amount,
        uint256 to
    );
    event FulfilledTokens(
        uint256 indexed timestamp,
        address indexed user,
        uint256 amount,
        uint256 from
    );

    constructor(
        IERC20 token_,
        uint256 limitPerSend_,
        address feeWallet_,
        address owner
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        limitPerSend = limitPerSend_;
        feeWallet = feeWallet_;
        token = token_;
    }

    /// @dev sends tokens on another chain by user
    /// @param amount amount of sending tokens
    /// @param to id of traget chain
    function send(uint256 amount, uint256 to) external whenNotPaused {
        require(amount > 0, 'Amount = 0');
        require(amount <= limitPerSend, 'Amount is over the limit per 1 send');

        _receiveTokens(msg.sender, amount);

        transactions[msg.sender].push(
            Transaction({
                user: msg.sender,
                timestamp: block.timestamp,
                amount: amount,
                from: block.chainid,
                to: to,
                nonce: nonce
            })
        );

        nonce++;
        emit SentTokens(block.timestamp, msg.sender, amount, to);
    }

    /// @dev fulfills transaction from another chainId
    /// @param transaction transaction struct
    function fulfill(Transaction memory transaction, bytes memory signature)
        external
        whenNotPaused
    {
        require(transaction.to == block.chainid, 'Wrong "to" chain id');

        bytes memory data = abi.encode(transaction);
        bytes32 hashedData = keccak256(data);

        require(!fulfilled[hashedData], 'Signature has been already fulfilled');

        require(hasRole(RELAYER_ROLE, _verify(hashedData, signature)), 'Wrong signature');

        fulfilled[hashedData] = true;
        transactions[transaction.user].push(transaction);

        uint256 currentFee = (transaction.amount * fee) / 10000;

        _dispenseTokens(transaction.user, transaction.amount - currentFee);
        if (fee != 0) _dispenseTokens(feeWallet, currentFee);

        emit FulfilledTokens(
            block.timestamp,
            transaction.user,
            transaction.amount,
            transaction.from
        );
    }

    // --- editable ---

    /// @dev interface for receiving tokens from user
    /// @param from user address
    /// @param amount amount of tokens
    function _receiveTokens(address from, uint256 amount) internal {
        // ERC20Burnable(address(token)).burnFrom(from, amount);
        SafeERC20.safeTransferFrom(token, from, address(this), amount);
    }

    /// @dev interface for dispensing tokens to user
    /// @param to user address
    /// @param amount amount of tokens
    function _dispenseTokens(address to, uint256 amount) internal {
        // IERC20Mintable(address(token)).mint(to, amount);
        SafeERC20.safeTransfer(token, to, amount);
    }

    // ------

    function _verify(bytes32 data, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(data), signature);
    }

    function getUserTransactions(address user)
        external
        view
        returns (Transaction[] memory)
    {
        return transactions[user];
    }

    function setFee(uint256 fee_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee != fee_, 'Current fee is equal to new fee');
        fee = fee_;
    }

    function setFeeWallet(address feeWallet_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(feeWallet_ != feeWallet_, 'Current feeWallet is equal to new feeWallet');
        feeWallet = feeWallet_;
    }

    function setLimitPerSend(uint256 limitPerSend_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(limitPerSend != limitPerSend_, 'Current limit is equal to new limit');
        limitPerSend = limitPerSend_;
    }

    function withdraw(
        IERC20 token_,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        SafeERC20.safeTransfer(token_, to, amount);
    }
}