// commit da41ad6c9caa5295bc268cc21b1b83764db6226a
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseACL.sol";

/// @title TransferAuthorizer - Manages ERC20/ETH transfer permissons.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice This checks token-receiver pairs, no amount is restricted.
contract TransferAuthorizer is BaseAuthorizer {
    bytes32 public constant NAME = "TransferAuthorizer";
    uint256 public constant VERSION = 2;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bytes32 public constant override TYPE = AuthType.TRANSFER;
    uint256 public constant flag = AuthFlags.HAS_PRE_CHECK_MASK;

    // function transfer(address recipient, uint256 amount)
    bytes4 constant TRANSFER_SELECTOR = 0xa9059cbb;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet tokenSet;

    mapping(address => EnumerableSet.AddressSet) tokenToReceivers;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);

    event TokenReceiverAdded(address indexed token, address indexed receiver);
    event TokenReceiverRemoved(address indexed token, address indexed receiver);

    struct TokenReceiver {
        address token;
        address receiver;
    }

    constructor(address _owner, address _caller) BaseAuthorizer(_owner, _caller) {}

    /// @notice Add token-receiver pairs. Use 0xee..ee for native ETH.
    function addTokenReceivers(TokenReceiver[] calldata tokenReceivers) external onlyOwner {
        for (uint i = 0; i < tokenReceivers.length; i++) {
            address token = tokenReceivers[i].token;
            address receiver = tokenReceivers[i].receiver;
            if (tokenSet.add(token)) {
                emit TokenAdded(token);
            }

            if (tokenToReceivers[token].add(receiver)) {
                emit TokenReceiverAdded(token, receiver);
            }
        }
    }

    function removeTokenReceivers(TokenReceiver[] calldata tokenReceivers) external onlyOwner {
        for (uint i = 0; i < tokenReceivers.length; i++) {
            address token = tokenReceivers[i].token;
            address receiver = tokenReceivers[i].receiver;
            if (tokenToReceivers[token].remove(receiver)) {
                emit TokenReceiverRemoved(token, receiver);
                if (tokenToReceivers[tokenReceivers[i].token].length() == 0) {
                    if (tokenSet.remove(token)) {
                        emit TokenRemoved(token);
                    }
                }
            }
        }
    }

    // View functions.

    function getAllToken() external view returns (address[] memory) {
        return tokenSet.values();
    }

    /// @dev View function allow user to specify the range in case we have very big token set
    ///      which can exhaust the gas of block limit.
    function getTokens(uint256 start, uint256 end) external view returns (address[] memory) {
        uint256 size = tokenSet.length();
        if (end > size) end = size;
        require(start < end, "start >= end");
        address[] memory _tokens = new address[](end - start);
        for (uint i = 0; i < end - start; i++) {
            _tokens[i] = tokenSet.at(start + i);
        }
        return _tokens;
    }

    function getTokenReceivers(address token) external view returns (address[] memory) {
        return tokenToReceivers[token].values();
    }

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        if (
            transaction.data.length >= 68 && // 4 + 32 + 32
            bytes4(transaction.data[0:4]) == TRANSFER_SELECTOR &&
            transaction.value == 0
        ) {
            // ETH transfer not allowed and token in white list.
            (address recipient /*uint256 amount*/, ) = abi.decode(transaction.data[4:], (address, uint256));
            address token = transaction.to;
            if (tokenToReceivers[token].contains(recipient)) {
                authData.result = AuthResult.SUCCESS;
                return authData;
            }
        } else if (transaction.data.length == 0 && transaction.value > 0) {
            // Contract call not allowed and token in white list.
            address recipient = transaction.to;
            if (tokenToReceivers[ETH].contains(recipient)) {
                authData.result = AuthResult.SUCCESS;
                return authData;
            }
        }
        authData.result = AuthResult.FAILED;
        authData.message = "transfer not allowed";
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        authData.result = AuthResult.SUCCESS;
    }
}