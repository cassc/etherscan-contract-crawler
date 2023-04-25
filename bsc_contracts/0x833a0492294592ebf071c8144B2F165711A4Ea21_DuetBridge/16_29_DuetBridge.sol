// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { Adminable } from "./libs/Adminable.sol";

import { IMessageReceiverApp } from "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";
import { MessageSenderLib } from "sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol";
import { MsgDataTypes } from "sgn-v2-contracts/contracts/message/libraries/MsgDataTypes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IBond } from "./interfaces/IBond.sol";
import { INaivePegToken } from "./interfaces/INaivePegToken.sol";
import { IMessageBus } from "./interfaces/IMessageBus.sol";

/**
 * @title SourceChainBridge
 * @dev This contract is used to transfer token from source chain to destination chain
 * @dev nomenclatures:
 - sourceChain: the chain where token transfer from.
 - originalChain: the chain where token initial supplied. (for duet token family, it's bsc)
 - destinationChain: the chain where token transfer to.
 - originalToken address: the token address on originalChain.
 */
contract DuetBridge is ReentrancyGuardUpgradeable, PausableUpgradeable, Adminable, IMessageReceiverApp {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    bytes public constant ACTION_TRANSFER_X = "";
    bytes public constant ACTION_REDEEM_X = "REDEEM";

    // chainId => messenger contract address
    mapping(uint64 => address) public chainContractMapping;
    // original token address => current chain token address
    mapping(address => address) public tokenMapping;

    address public messageBus;
    /**
     * current chain id
     */
    uint64 public chainId;
    uint64 public originalChainId;
    mapping(address => bool) public executors;

    event MessageWithTransferReceived(
        address sender,
        address token,
        uint256 amount,
        uint64 srcChainId,
        bytes action,
        address executor
    );
    event MessageWithTransferRefunded(address sender, address token, uint256 amount, bytes action, address executor);
    event TransferX(
        bytes32 transferId,
        address sender,
        address token,
        uint256 amount,
        bytes action,
        uint64 destChainId,
        uint256 userFees,
        uint256 fees
    );

    event ChainAdded(uint64 chainId, address chainContract, address previousChainContract);
    event TokenAdded(address originalToken, address token, address previousToken);

    event ExecutorChanged(address executor, bool enabled, bool previousEnabled);
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "DuetBridge: caller is not message bus");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function isOriginalChain() public view returns (bool) {
        return chainId == originalChainId;
    }

    function initialize(address messageBus_, uint64 chainId_, uint64 originalChainId_) external initializer {
        require(chainId_ > 0, "DuetBridge: chainId must be greater than 0");
        require(originalChainId_ > 0, "DuetBridge: chainId must be greater than 0");
        require(messageBus_ != address(0), "DuetBridge: messageBus must not be zero address");

        messageBus = messageBus_;
        chainId = chainId_;
        originalChainId = originalChainId_;

        _setAdmin(msg.sender);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    function addChainContract(uint64 chainId_, address chainContract_) external onlyAdmin {
        address previousChainContract = chainContractMapping[chainId_];
        chainContractMapping[chainId_] = chainContract_;
        emit ChainAdded(chainId_, chainContract_, previousChainContract);
    }

    // @dev TODO Currently, anyone can serve as an executor.
    function addExecutor(address executor_) external onlyAdmin {
        emit ExecutorChanged(executor_, true, executors[executor_]);
        executors[executor_] = true;
    }

    function removeExecutor(address executor_) external onlyAdmin {
        emit ExecutorChanged(executor_, true, executors[executor_]);
        executors[executor_] = false;
    }

    function addToken(address originalToken_, address currentChainToken_) external onlyAdmin {
        require(originalToken_ != address(0), "DuetBridge: originalToken must not be zero address");
        address previousToken = tokenMapping[originalToken_];
        if (isOriginalChain()) {
            require(
                currentChainToken_ == originalToken_,
                "DuetBridge: currentChainToken must be originalToken on originalChain"
            );
        } else {
            INaivePegToken currentChainToken = INaivePegToken(currentChainToken_);
            require(
                currentChainToken.originalToken() != address(0),
                "DuetBridge: currentChainToken.originalToken() must not be zero address"
            );
            require(
                currentChainToken.originalToken() == originalToken_,
                "DuetBridge: originalToken must be equal to currentChainToken.originalToken()"
            );
        }

        tokenMapping[originalToken_] = currentChainToken_;
        emit TokenAdded(originalToken_, currentChainToken_, previousToken);
    }

    /**
     * @dev called by users on source chain to send tokens to destination chain
     */
    function transferX(address originalToken_, uint256 amount_, uint64 destChainId_, uint64 nonce_) external payable {
        _transferXForUser(msg.sender, originalToken_, amount_, destChainId_, nonce_, ACTION_TRANSFER_X);
    }

    function _transferXForUser(
        address user_,
        address originalToken_,
        uint256 amount_,
        uint64 destChainId_,
        uint64 nonce_,
        bytes memory action_
    ) internal whenNotPaused nonReentrant {
        require(destChainId_ != chainId, "DuetBridge: destChainId must not be current chain id");
        require(originalToken_ != address(0), "DuetBridge: originalToken must not be zero address");
        require(amount_ > 0, "DuetBridge: amount must be greater than 0");
        require(nonce_ > 0, "DuetBridge: nonce must be greater than 0");
        address currentChainToken = tokenMapping[originalToken_];
        require(currentChainToken != address(0), "DuetBridge: token not supported");
        address destChainContract = chainContractMapping[destChainId_];
        require(destChainContract != address(0), "DuetBridge: destChain not supported");

        bytes memory message = abi.encode(user_, action_);
        uint256 userFee = _calcUserFee(message);
        require(
            msg.value >= userFee,
            string.concat("DuetBridge: msg.value must be greater than ", Strings.toString(userFee))
        );
        uint256 celerFee = IMessageBus(messageBus).calcFee(message);

        _transferFrom(user_, currentChainToken, amount_);
        bytes32 transferId = MessageSenderLib.sendMessageWithTransfer(
            destChainContract,
            originalToken_,
            amount_,
            destChainId_,
            nonce_,
            // maxSlippage, only for MsgDataTypes.BridgeSendType.Liquidity
            0,
            message,
            isOriginalChain() ? MsgDataTypes.BridgeSendType.Liquidity : MsgDataTypes.BridgeSendType.PegBurn,
            messageBus,
            celerFee
        );
        emit TransferX(transferId, user_, originalToken_, amount_, action_, destChainId_, msg.value, celerFee);
    }

    // called by MessageBus on destination chain to receive message, record and emit info.
    // the associated token transfer is guaranteed to have already been received
    function executeMessageWithTransfer(
        address sourceContract_,
        address originalToken_,
        uint256 amount_,
        uint64 sourceChainId_,
        bytes memory message_,
        address executor_
    ) external payable override onlyMessageBus whenNotPaused nonReentrant returns (ExecutionStatus) {
        require(sourceChainId_ != chainId, "DuetBridge: sourceChainId must not be current chain id");
        require(chainContractMapping[sourceChainId_] == sourceContract_, "DuetBridge: Invalid sourceContract_");
        address currentChainToken = tokenMapping[originalToken_];
        require(currentChainToken != address(0), "DuetBridge: token not supported");
        (address sender, bytes memory action) = abi.decode((message_), (address, bytes));

        _transferTo(sender, currentChainToken, amount_);

        emit MessageWithTransferReceived(sender, originalToken_, amount_, sourceChainId_, action, executor_);
        return ExecutionStatus.Success;
    }

    // called by MessageBus on source chain to handle message with failed token transfer
    // the associated token transfer is guaranteed to have already been refunded
    function executeMessageWithTransferRefund(
        address originalToken_,
        uint256 amount_,
        bytes calldata message_,
        address executor_
    ) external payable override onlyMessageBus nonReentrant returns (ExecutionStatus) {
        (address sender, bytes memory action) = abi.decode((message_), (address, bytes));
        address currentChainToken = tokenMapping[originalToken_];

        _transferTo(sender, currentChainToken, amount_);

        emit MessageWithTransferRefunded(sender, originalToken_, amount_, action, executor_);
        return ExecutionStatus.Success;
    }

    function getTransferXFee() public view returns (uint256) {
        return _calcUserFee(abi.encode(address(this), ACTION_TRANSFER_X));
    }

    function _calcUserFee(bytes memory message_) internal view returns (uint256) {
        // To cover the cost of the execution on the dest chain, we triple the fee
        return IMessageBus(messageBus).calcFee(message_) * 3;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function _transferFrom(address from_, address token_, uint256 amount_) internal {
        if (isOriginalChain()) {
            // When executing transferX on originalChain, the user's tokens will be locked in the DuetBridge contract.
            IERC20MetadataUpgradeable(token_).safeTransferFrom(from_, address(this), amount_);
        } else {
            // If it is not on originalChain, the tokens will be burned.
            INaivePegToken(token_).burnFrom(from_, amount_);
        }
    }

    function _transferTo(address to_, address token_, uint256 amount_) internal {
        if (isOriginalChain()) {
            // When executing refund or tokens received on originalChain, the user's tokens will be unlocked from the DuetBridge contract.
            IERC20MetadataUpgradeable(token_).transfer(to_, amount_);
        } else {
            // If it is not on originalChain, tokens will be minted (as a burn rollback operation when refund).
            INaivePegToken(token_).mint(to_, amount_);
        }
    }

    /**
     * @notice Called by MessageBus to execute a message
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus) {}

    // same as above, except that sender is an non-evm chain address,
    // otherwise same as above.
    function executeMessage(
        bytes calldata _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus) {}

    /**
     * @notice Only called by MessageBus if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus) {}
}