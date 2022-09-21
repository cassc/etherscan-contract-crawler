// SPDX-License-Identifier: MIT
pragma solidity >0.8.8;

/* Library Imports */
import { AddressAliasHelper } from "@eth-optimism/contracts/contracts/standards/AddressAliasHelper.sol";
import { Lib_AddressResolver } from "@eth-optimism/contracts/contracts/libraries/resolver/Lib_AddressResolver.sol";
import { Lib_OVMCodec } from "@eth-optimism/contracts/contracts/libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressManager } from "@eth-optimism/contracts/contracts/libraries/resolver/Lib_AddressManager.sol";
import { Lib_SecureMerkleTrie } from "@eth-optimism/contracts/contracts/libraries/trie/Lib_SecureMerkleTrie.sol";
import { Lib_DefaultValues } from "@eth-optimism/contracts/contracts/libraries/constants/Lib_DefaultValues.sol";
import { Lib_PredeployAddresses } from "@eth-optimism/contracts/contracts/libraries/constants/Lib_PredeployAddresses.sol";
import { Lib_CrossDomainUtils } from "@eth-optimism/contracts/contracts/libraries/bridge/Lib_CrossDomainUtils.sol";

/* Interface Imports */
import { IL1CrossDomainMessenger } from "@eth-optimism/contracts/contracts/L1/messaging/IL1CrossDomainMessenger.sol";
import { IL1DepositHash } from "./IL1DepositHash.sol";
import { ICanonicalTransactionChain } from "@eth-optimism/contracts/contracts/L1/rollup/ICanonicalTransactionChain.sol";
import { IStateCommitmentChain } from "@eth-optimism/contracts/contracts/L1/rollup/IStateCommitmentChain.sol";

/* External Imports */
import { OwnableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from
    "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title L1CrossDomainMessengerFast
 * @dev The L1 Cross Domain Messenger contract sends messages from L1 to L2, and relays messages from L2 onto L1.
 * In the event that a message sent from L1 to L2 is rejected for exceeding the L2 epoch gas limit, it can be resubmitted
 * via this contract's replay function.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract L1CrossDomainMessengerFast is
    IL1CrossDomainMessenger,
    Lib_AddressResolver,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{

    /**********
     * Events *
     **********/


    event MessageBlocked(
        bytes32 indexed _xDomainCalldataHash
    );

    event MessageAllowed(
        bytes32 indexed _xDomainCalldataHash
    );

    /**********************
     * Contract Variables *
     **********************/

    mapping (bytes32 => bool) public blockedMessages;
    mapping (bytes32 => bool) public relayedMessages;
    mapping (bytes32 => bool) public successfulMessages;
    mapping (bytes32 => bool) public failedMessages;

    address internal xDomainMsgSender = Lib_DefaultValues.DEFAULT_XDOMAIN_SENDER;

    /***************
     * Constructor *
     ***************/

    /**
     * This contract is intended to be behind a delegate proxy.
     * We pass the zero address to the address resolver just to satisfy the constructor.
     * We still need to set this value in initialize().
     */
    constructor()
        Lib_AddressResolver(address(0))
    {}

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Modifier to enforce that, if configured, only the OVM_L2MessageRelayer contract may
     * successfully call a method.
     */
    modifier onlyRelayer() {
        address relayer = resolve("OVM_L2MessageRelayer");
        if (relayer != address(0)) {
            require(
                msg.sender == relayer,
                "Only OVM_L2MessageRelayer can relay L2-to-L1 messages."
            );
        }
        _;
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    function initialize(
        address _libAddressManager
    )
        public
        initializer
    {
        require(
            address(libAddressManager) == address(0),
            "L1CrossDomainMessenger already intialized."
        );
        libAddressManager = Lib_AddressManager(_libAddressManager);
        xDomainMsgSender = Lib_DefaultValues.DEFAULT_XDOMAIN_SENDER;

        // Initialize upgradable OZ contracts
        __Context_init_unchained(); // Context is a dependency for both Ownable and Pausable
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /**
     * Pause fast exit relays
     */
    function pause()
        external
        onlyOwner() {
        _pause();
    }

    /**
     * UnPause fast exit relays
     */
    function unpause()
        external
        onlyOwner() {
        _unpause();
    }

    /**
     * Block a message.
     * @param _xDomainCalldataHash Hash of the message to block.
     */
    function blockMessage(
        bytes32 _xDomainCalldataHash
    )
        external
        onlyOwner
    {
        blockedMessages[_xDomainCalldataHash] = true;
        emit MessageBlocked(_xDomainCalldataHash);
    }

    /**
     * Allow a message.
     * @param _xDomainCalldataHash Hash of the message to block.
     */
    function allowMessage(
        bytes32 _xDomainCalldataHash
    )
        external
        onlyOwner
    {
        blockedMessages[_xDomainCalldataHash] = false;
        emit MessageAllowed(_xDomainCalldataHash);
    }

    function xDomainMessageSender()
        public
        override
        view
        returns (
            address
        )
    {
        require(xDomainMsgSender != Lib_DefaultValues.DEFAULT_XDOMAIN_SENDER, "xDomainMessageSender is not set");
        return xDomainMsgSender;
    }

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    )
        override
        public
    {
        revert("Sending via this messenger is disabled");
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Relays a cross domain message to a contract.
     * @inheritdoc IL1CrossDomainMessenger
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        L2MessageInclusionProof memory _proof
    )
        override
        public
        onlyRelayer
        nonReentrant
        whenNotPaused
    {
        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            _sender,
            _message,
            _messageNonce
        );

        require(
            _verifyXDomainMessage(
                xDomainCalldata,
                _proof
            ) == true,
            "Provided message could not be verified."
        );

        bytes32 xDomainCalldataHash = keccak256(xDomainCalldata);

        require(
            successfulMessages[xDomainCalldataHash] == false,
            "Provided message has already been received."
        );

        require(
            blockedMessages[xDomainCalldataHash] == false,
            "Provided message has been blocked."
        );

        require(
            _target != resolve("CanonicalTransactionChain"),
            "Cannot send L2->L1 messages to L1 system contracts."
        );

        xDomainMsgSender = _sender;
        (bool success, ) = _target.call(_message);
        xDomainMsgSender = Lib_DefaultValues.DEFAULT_XDOMAIN_SENDER;

        // Mark the message as received if the call was successful. Ensures that a message can be
        // relayed multiple times in the case that the call reverted.
        if (success == true) {
            successfulMessages[xDomainCalldataHash] = true;
            emit RelayedMessage(xDomainCalldataHash);
        } else {
            failedMessages[xDomainCalldataHash] == true;
            emit FailedRelayedMessage(xDomainCalldataHash);
        }

        // Store an identifier that can be used to prove that the given message was relayed by some
        // user. Gives us an easy way to pay relayers for their work.
        bytes32 relayId = keccak256(
            abi.encodePacked(
                xDomainCalldata,
                msg.sender,
                block.number
            )
        );
        relayedMessages[relayId] = true;
    }

    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        L2MessageInclusionProof memory _proof,
        bytes32 _standardBridgeDepositHash,
        bytes32 _lpDepositHash
    )
        public
        nonReentrant
        whenNotPaused
    {
        // verify hashes
        _verifyDepositHashes(_standardBridgeDepositHash, _lpDepositHash);

        relayMessage(_target, _sender, _message, _messageNonce, _proof);
    }

    /**
     * Replays a cross domain message to the target messenger.
     * @inheritdoc IL1CrossDomainMessenger
     */
    function replayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _queueIndex,
        uint32 _oldGasLimit,
        uint32 _newGasLimit
    )
        override
        public
    {
        revert("Sending via this messenger is disabled");
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Verifies that the given message is valid.
     * @param _xDomainCalldata Calldata to verify.
     * @param _proof Inclusion proof for the message.
     * @return Whether or not the provided message is valid.
     */
    function _verifyXDomainMessage(
        bytes memory _xDomainCalldata,
        L2MessageInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        return (
            _verifyStateRootProof(_proof)
            && _verifyStorageProof(_xDomainCalldata, _proof)
        );
    }

    /**
     * Verifies that the state root within an inclusion proof is valid.
     * @param _proof Message inclusion proof.
     * @return Whether or not the provided proof is valid.
     */
    function _verifyStateRootProof(
        L2MessageInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        IStateCommitmentChain ovmStateCommitmentChain = IStateCommitmentChain(
            resolve("StateCommitmentChain")
        );

        return (
            ovmStateCommitmentChain.verifyStateCommitment(
                _proof.stateRoot,
                _proof.stateRootBatchHeader,
                _proof.stateRootProof
            )
        );
    }

    /**
     * Verifies that the storage proof within an inclusion proof is valid.
     * @param _xDomainCalldata Encoded message calldata.
     * @param _proof Message inclusion proof.
     * @return Whether or not the provided proof is valid.
     */
    function _verifyStorageProof(
        bytes memory _xDomainCalldata,
        L2MessageInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        bytes32 storageKey = keccak256(
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        _xDomainCalldata,
                        Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER
                    )
                ),
                uint256(0)
            )
        );

        (
            bool exists,
            bytes memory encodedMessagePassingAccount
        ) = Lib_SecureMerkleTrie.get(
            abi.encodePacked(Lib_PredeployAddresses.L2_TO_L1_MESSAGE_PASSER),
            _proof.stateTrieWitness,
            _proof.stateRoot
        );

        require(
            exists == true,
            "Message passing predeploy has not been initialized or invalid proof provided."
        );

        Lib_OVMCodec.EVMAccount memory account = Lib_OVMCodec.decodeEVMAccount(
            encodedMessagePassingAccount
        );

        return Lib_SecureMerkleTrie.verifyInclusionProof(
            abi.encodePacked(storageKey),
            abi.encodePacked(uint8(1)),
            _proof.storageTrieWitness,
            account.storageRoot
        );
    }

    function _verifyDepositHashes(
        bytes32 _standardBridgeDepositHash,
        bytes32 _lpDepositHash
    )
        internal
    {
        // fetch address of standard bridge and LP1
        address standardBridge = resolve("Proxy__L1StandardBridge");
        address L1LP = resolve("Proxy__L1LiquidityPool");

        if (block.number == IL1DepositHash(standardBridge).lastHashUpdateBlock()) {
            require(_standardBridgeDepositHash == IL1DepositHash(standardBridge).priorDepositInfoHash(), "Standard Bridge hashes do not match");
        } else {
            require(_standardBridgeDepositHash == IL1DepositHash(standardBridge).currentDepositInfoHash(), "Standard Bridge hashes do not match");
        }

        if (block.number == IL1DepositHash(L1LP).lastHashUpdateBlock()) {
            require(_lpDepositHash == IL1DepositHash(L1LP).priorDepositInfoHash(), "LP1 hashes do not match");
        } else {
            require(_lpDepositHash == IL1DepositHash(L1LP).currentDepositInfoHash(), "LP1 hashes do not match");
        }
    }
}