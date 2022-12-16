// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IForwarderRegistry} from "@animoca/ethereum-contracts/contracts/metatx/interfaces/IForwarderRegistry.sol";
import {ERC20Storage} from "@animoca/ethereum-contracts/contracts/token/ERC20/libraries/ERC20Storage.sol";
import {Create2} from "@maticnetwork/fx-portal/contracts/lib/Create2.sol";
import {ERC20Receiver} from "@animoca/ethereum-contracts/contracts/token/ERC20/ERC20Receiver.sol";
import {FxBaseRootTunnel} from "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
import {FxTokenMapping} from "./../../FxTokenMapping.sol";
import {FxERC20TunnelEvents} from "./../../FxERC20TunnelEvents.sol";
import {ForwarderRegistryContext} from "@animoca/ethereum-contracts/contracts/metatx/ForwarderRegistryContext.sol";

/// @title FxERC20RootTunnel
/// @notice Base contract for an Fx root ERC20 tunnel.
abstract contract FxERC20RootTunnel is FxBaseRootTunnel, FxTokenMapping, FxERC20TunnelEvents, ERC20Receiver, Create2, ForwarderRegistryContext {
    bytes32 public immutable childTokenProxyCodeHash;

    /// @notice Thrown when a deposit request refers to an invalid token mapping.
    /// @param childToken The child token.
    /// @param expectedRootToken The expected root token.
    /// @param actualRootToken The actual root token.
    error FxERC20InvalidMappingOnExit(address childToken, address expectedRootToken, address actualRootToken);

    /// @notice Thrown if a deposit recipient is the zero address.
    error FxERC20InvalidDepositAddress();

    constructor(
        address checkpointManager,
        address fxRoot,
        address fxERC20Token,
        IForwarderRegistry forwarderRegistry
    ) FxBaseRootTunnel(checkpointManager, fxRoot) ForwarderRegistryContext(forwarderRegistry) {
        // compute child token proxy code hash
        childTokenProxyCodeHash = keccak256(minimalProxyCreationCode(fxERC20Token));
    }

    /// @notice Map a token to enable its movement via the Fx Portal
    /// @param rootToken address of token on root chain
    function mapToken(address rootToken) public returns (address childToken) {
        childToken = rootToChildToken[rootToken];
        if (childToken != address(0x0)) {
            return childToken;
        }

        // send the mapping request to the child chain
        _sendMessageToChild(abi.encode(MAP_TOKEN, abi.encode(rootToken, _encodeChildTokenInitArgs(rootToken))));

        // compute child token address before deployment using create2
        bytes32 salt = keccak256(abi.encodePacked(rootToken));
        childToken = computedCreate2Address(salt, childTokenProxyCodeHash, fxChildTunnel);

        // add into mapped tokens
        rootToChildToken[rootToken] = childToken;
        emit FxERC20TokenMapping(rootToken, childToken);
    }

    /// @notice Handles the receipt of ERC20 tokens as a deposit request.
    /// @dev Note: this function is called by an {ERC20SafeTransfer} contract after a safe transfer.
    // @param operator The initiator of the safe transfer.
    /// @param from The previous tokens owner.
    /// @param value The amount of tokens transferred.
    /// @param data Empty if the receiver is the same as the tokens sender, else the abi-encoded address of the receiver.
    /// @return magicValue `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` (`0x4fc35859`) to accept, any other value to refuse.
    function onERC20Received(address, address from, uint256 value, bytes calldata data) external returns (bytes4 magicValue) {
        address receiver = from;
        if (data.length != 0) {
            (receiver) = abi.decode(data, (address));
            if (receiver == address(0)) {
                revert FxERC20InvalidDepositAddress();
            }
        }
        _deposit(msg.sender, from, receiver, value);
        _depositReceivedTokens(msg.sender, value);

        return ERC20Storage.ERC20_RECEIVED;
    }

    /// @notice Deposits an `amount` of `rootToken` by and for the message sender.
    /// @notice Note: Approval for `amount` of `rootToken` must have been previously given to this contract.
    /// @dev Reverts if the token transfer fails for any reason.
    /// @param rootToken The ERC20 root token.
    /// @param amount The amount of tokens to deposit.
    function deposit(address rootToken, uint256 amount) external {
        address depositor = _msgSender();
        _deposit(rootToken, depositor, depositor, amount);
        _depositTokensFrom(rootToken, depositor, amount);
    }

    /// @notice Deposits an `amount` of `rootToken` by the message sender and for a `receiver`.
    /// @notice Note: Approval for `amount` of `rootToken` must have been previously given to this contract.
    /// @dev Reverts with `FxERC20TokenNotMapped` if `childToken has not been deployed through a mapping request.
    /// @dev Reverts if the token transfer fails for any reason.
    /// @param rootToken The ERC20 root token.
    /// @param receiver The account receiving the deposit.
    /// @param amount The amount of tokens to deposit.
    function depositTo(address rootToken, address receiver, uint256 amount) external {
        if (receiver == address(0)) {
            revert FxERC20InvalidDepositAddress();
        }
        address depositor = _msgSender();
        _deposit(rootToken, depositor, receiver, amount);
        _depositTokensFrom(rootToken, depositor, amount);
    }

    function _deposit(address rootToken, address depositor, address receiver, uint256 amount) internal {
        bytes memory message = abi.encode(DEPOSIT, abi.encode(rootToken, depositor, receiver, amount));
        _sendMessageToChild(message);
        emit FxERC20Deposit(rootToken, mapToken(rootToken), depositor, receiver, amount);
    }

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (address rootToken, address childToken, address withdrawer, address receiver, uint256 amount) = abi.decode(
            data,
            (address, address, address, address, uint256)
        );

        // validate mapping for root to child
        address mappedChildToken = rootToChildToken[rootToken];
        if (childToken != mappedChildToken) {
            revert FxERC20InvalidMappingOnExit(rootToken, childToken, mappedChildToken);
        }

        _withdraw(rootToken, receiver, amount);

        emit FxERC20Withdrawal(rootToken, childToken, withdrawer, receiver, amount);
    }

    /// @notice Returns the abi-encoded arguments for the Fx child token initialization function.
    /// @param rootToken The root token address.
    function _encodeChildTokenInitArgs(address rootToken) internal virtual returns (bytes memory);

    /// @notice Deposits tokens to the child chain when transferred to this contract via onERC20Received function.
    /// @dev When this function is called, this contract has already become the owner of the tokens.
    /// @param rootToken The root token address.
    /// @param amount The token amount to deposit.
    function _depositReceivedTokens(address rootToken, uint256 amount) internal virtual;

    /// @notice Deposits tokens to the child chain from a withdrawer.
    /// @dev When this function is called, the withdrawer still owns the tokens.
    /// @param rootToken The root token address.
    /// @param depositor The depositor address.
    /// @param amount The token amount to deposit.
    function _depositTokensFrom(address rootToken, address depositor, uint256 amount) internal virtual;

    /// @notice Withdraws the tokens received from the child chain.
    /// @param rootToken The root token address.
    /// @param receiver The receiver address.
    /// @param amount The token amount to deposit.
    function _withdraw(address rootToken, address receiver, uint256 amount) internal virtual;
}