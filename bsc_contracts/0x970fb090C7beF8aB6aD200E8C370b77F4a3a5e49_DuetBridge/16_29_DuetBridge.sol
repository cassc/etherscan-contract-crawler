// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { Adminable } from "./libs/Adminable.sol";

import { MessageSenderLib } from "sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol";
import { IMessageReceiverApp } from "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";
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
contract DuetBridge is ReentrancyGuardUpgradeable, PausableUpgradeable, Adminable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    bytes public constant ACTION_TRANSFER_X = "";
    bytes public constant ACTION_REDEEM_X = "REDEEM";

    // chainId => messenger contract address
    mapping(uint64 => address) public chainContractMapping;
    // original token address => current chain token address
    mapping(address => address) public tokenMapping;
    // original token address => min transfer amount
    mapping(address => uint256) public tokenMinTransfer;

    address public messageBus;
    uint64 public originalChainId;
    mapping(address => bool) public executors;

    mapping(address => uint64) public nonces;
    // to identify the transfer
    // user => sourceChain => nonce => executed
    mapping(address => mapping(uint64 => mapping(uint64 => bool))) public receivedNonces;

    event ReceiveX(
        bytes32 transferId,
        address sender,
        address token,
        uint256 amount,
        uint64 sourceChainId,
        uint64 nonce,
        address executor,
        bytes action
    );
    event TransferX(
        bytes32 transferId,
        address sender,
        address token,
        uint256 amount,
        uint64 destChainId,
        uint64 nonce,
        uint256 userFees,
        uint256 fees,
        bytes action
    );

    event ChainAdded(uint64 chainId, address chainContract, address previousChainContract);
    event TokenAdded(address originalToken, address token, address previousToken, uint256 minTransferAmount);

    event ExecutorChanged(address executor, bool enabled, bool previousEnabled);
    event NativeBalanceRetrieved(address operator, uint256 amount);

    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "DuetBridge: caller is not message bus");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function isOriginalChain() public view returns (bool) {
        return block.chainid == originalChainId;
    }

    function initialize(address messageBus_, uint64 originalChainId_) external initializer {
        require(originalChainId_ > 0, "DuetBridge: chainId must be greater than 0");
        require(messageBus_ != address(0), "DuetBridge: messageBus must not be zero address");

        messageBus = messageBus_;
        originalChainId = originalChainId_;

        _setAdmin(msg.sender);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    function addChainContract(uint64 chainId_, address chainContract_) external onlyAdmin {
        if (chainId_ == block.chainid) {
            require(chainContract_ == address(this), "DuetBridge: invalid chainContract_");
        }
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
        emit ExecutorChanged(executor_, false, executors[executor_]);
        delete executors[executor_];
    }

    function addToken(
        address originalToken_,
        address currentChainToken_,
        uint256 minTransferAmount_
    ) external onlyAdmin {
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
        tokenMinTransfer[originalToken_] = minTransferAmount_;
        emit TokenAdded(originalToken_, currentChainToken_, previousToken, minTransferAmount_);
    }

    /**
     * @dev called by users on source chain to send tokens to destination chain
     */
    function transferX(address originalToken_, uint256 amount_, uint64 destChainId_) external payable {
        _transferXForUser(msg.sender, originalToken_, amount_, destChainId_, ACTION_TRANSFER_X);
    }

    function _transferXForUser(
        address user_,
        address originalToken_,
        uint256 amount_,
        uint64 destChainId_,
        bytes memory action_
    ) internal whenNotPaused nonReentrant returns (bytes32 transferId) {
        require(destChainId_ != block.chainid, "DuetBridge: destChainId must not be current chain id");
        require(originalToken_ != address(0), "DuetBridge: originalToken must not be zero address");
        require(amount_ > 0, "DuetBridge: amount must be greater than 0");
        address currentChainToken = tokenMapping[originalToken_];
        require(currentChainToken != address(0), "DuetBridge: token not supported");
        address destChainContract = chainContractMapping[destChainId_];
        require(destChainContract != address(0), "DuetBridge: destChain not supported");
        uint64 nonce = ++nonces[user_];
        bytes memory message = encodeMessage(user_, originalToken_, amount_, nonce, action_);
        uint256 userFee = _calcUserFee(message);
        require(
            msg.value >= userFee,
            string.concat("DuetBridge: msg.value must be greater than ", Strings.toString(userFee))
        );
        uint256 celerFee = IMessageBus(messageBus).calcFee(message);

        _transferFrom(user_, currentChainToken, amount_);
        MessageSenderLib.sendMessage(destChainContract, destChainId_, message, messageBus, celerFee);
        transferId = computeTransferId(user_, uint64(block.chainid), originalToken_, amount_, destChainId_, nonce);
        emit TransferX(transferId, user_, originalToken_, amount_, destChainId_, nonce, msg.value, celerFee, action_);
        return transferId;
    }

    function executeMessage(
        address sourceContract_,
        uint64 sourceChainId_,
        bytes calldata message_,
        address executor_
    ) external payable onlyMessageBus whenNotPaused nonReentrant returns (IMessageReceiverApp.ExecutionStatus) {
        require(sourceChainId_ != block.chainid, "DuetBridge: sourceChainId must not be current chain id");
        require(chainContractMapping[sourceChainId_] == sourceContract_, "DuetBridge: Invalid sourceContract_");

        (address sender, address originalToken, uint256 amount, uint64 nonce, bytes memory action) = decodeMessage(
            message_
        );
        require(!receivedNonces[sender][sourceChainId_][nonce], "DuetBridge: nonce already executed");
        receivedNonces[sender][sourceChainId_][nonce] = true;
        address currentChainToken = tokenMapping[originalToken];
        require(currentChainToken != address(0), "DuetBridge: token not supported");

        _transferTo(sender, currentChainToken, amount);
        emit ReceiveX(
            computeTransferId(sender, sourceChainId_, originalToken, amount, uint64(block.chainid), nonce),
            sender,
            originalToken,
            amount,
            sourceChainId_,
            nonce,
            executor_,
            action
        );
        return IMessageReceiverApp.ExecutionStatus.Success;
    }

    function getTransferXFee(address user_, uint256 amount_) public view returns (uint256) {
        return _calcUserFee(encodeMessage(address(this), address(this), amount_, nonces[user_] + 1, ACTION_TRANSFER_X));
    }

    function _calcUserFee(bytes memory message_) internal view returns (uint256) {
        // To cover the cost of the execution on the dest chain, we triple the fee
        return IMessageBus(messageBus).calcFee(message_) * 3;
    }

    function retrieveNativeBalance() external nonReentrant onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "DuetBridge: nothing to retrieve");
        payable(msg.sender).transfer(balance);
        emit NativeBalanceRetrieved(msg.sender, balance);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function computeTransferId(
        address user_,
        uint64 sourceChainId_,
        address originalToken_,
        uint256 amount_,
        uint64 destChainId_,
        uint64 nonce_
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(user_, sourceChainId_, originalToken_, amount_, destChainId_, nonce_));
    }

    function encodeMessage(
        address user_,
        address originalToken_,
        uint256 amount_,
        uint64 nonce_,
        bytes memory action_
    ) public pure returns (bytes memory) {
        return abi.encode(user_, originalToken_, amount_, nonce_, action_);
    }

    function decodeMessage(
        bytes calldata message_
    ) public pure returns (address user_, address originalToken_, uint256 amount_, uint64 nonce, bytes memory action_) {
        return abi.decode(message_, (address, address, uint256, uint64, bytes));
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
}