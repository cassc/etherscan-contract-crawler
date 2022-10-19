// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IBridge.sol";

/// @title Root network bridge contract on ethereum
/// @author Root Network
/// @notice Provides methods for verifying messages from the validator set
contract Bridge is IBridge, IBridgeReceiver, Ownable, ReentrancyGuard, ERC165 {
    using ECDSA for bytes32;

    // map from validator set nonce to keccak256 digest of validator ECDSA addresses (i.e bridge session keys)
    // these should be encoded in sorted order matching `pallet_session::Module<T>::validators()` to create the digest
    // signatures from a threshold of these addresses are considered approved by the protocol
    mapping(uint => bytes32) public validatorSetDigests;
    // Nonce for validator set changes
    uint32 public activeValidatorSetId;
    // Nonce of the next outgoing event
    uint public sentEventId;
    // Map of verified incoming event nonces
    // will only validate one event per nonce.
    // Verification/submission out of order is ok.
    mapping(uint => bool) public verifiedEventIds;
    // Fee for message verification
    // Offsets bridge upkeep costs i.e updating the validator set
    uint public bridgeFee = 4e15; // 0.004 ether
    // Acceptance threshold in %
    uint public thresholdPercent = 60;
    // Number of staking eras before a bridge message will be considered expired
    uint public proofTTL = 7;
    // Whether the bridge is active or not
    bool public active = false;
    // Max reward paid out to successful caller of `setValidator`
    uint public maxRewardPayout = 1 ether;
    // The bridge pallet (pseudo) address this contract is paired with
    address public palletAddress =
        address(0x6D6f646C65746879627264670000000000000000);
    // Max message length allowed
    uint public maxMessageLength = 1024; // 1kb
    // Fee required to be paid for SendMessage calls
    uint256 internal _sendMessageFee = 3e14; // 0.0003 ether
    // Message fees accumulated by the bridge
    uint public accumulatedMessageFees;

    event MessageReceived(
        uint indexed eventId,
        address indexed source,
        address indexed destinate,
        bytes message
    );
    event SetValidators(
        bytes32 indexed validatorSetDigest,
        uint256 indexed reward,
        uint32 indexed validatorSetId
    );
    event ForceSetActiveValidators(
        bytes32 indexed validatorSetDigest,
        uint32 indexed validatorSetId
    );
    event ForceSetHistoricValidators(
        bytes32 indexed validatorSetDigest,
        uint32 indexed validatorSetId
    );
    event BridgeFeeUpdated(uint indexed bridgeFee);
    event ThresholdUpdated(uint indexed thresholdPercent);
    event ProofTTLUpdated(uint indexed proofTTL);
    event BridgeActiveUpdated(bool indexed active);
    event MaxRewardPayoutUpdated(uint indexed maxRewardPayout);
    event PalletAddressUpdated(address indexed palletAddress);
    event MaxMessageLengthUpdated(uint indexed maxMessageLength);
    event SentEventIdUpdated(uint indexed _newId);
    event Endowed(uint256 indexed amount);
    event EtherWithdrawn(address _to, uint256 _amount);
    event WithdrawnMessageFees(address indexed recipient, uint indexed amount);
    event SendMessageFeeUpdated(uint256 indexed sendMessageFee);

    /// @notice Emit an event for the remote chain
    function sendMessage(address destination, bytes calldata message)
        external
        payable
        override
    {
        require(active, "Bridge: bridge inactive");
        require(message.length <= maxMessageLength, "Bridge: msg exceeds max length");
        require(msg.value >= _sendMessageFee, "Bridge: insufficient message fee");
        accumulatedMessageFees += msg.value;
        emit SendMessage(sentEventId++, msg.sender, destination, message, msg.value);
    }

    function sendMessageFee() external override view returns (uint256) {
        return _sendMessageFee;
    }

    /// @notice Receive a message from the remote chain
    /// @param proof contains a list of validator signature data and respective addresses - retrieved via RPC call from the remote chain
    function receiveMessage(
        address source,
        address destination,
        bytes calldata appMessage,
        EventProof calldata proof
    ) external payable override {
        require(
            msg.value >= bridgeFee || destination == address(this),
            "Bridge: must supply bridge fee"
        );
        require(appMessage.length > 0, "Bridge: empty message");

        bytes memory preimage = abi.encode(
            source,
            destination,
            appMessage,
            proof.validatorSetId,
            proof.eventId
        );
        _verifyMessage(preimage, proof);

        emit MessageReceived(proof.eventId, source, destination, appMessage);

        // call bridge receiver
        IBridgeReceiver(destination).onMessageReceived(source, appMessage);
    }

    /// @notice Verify a message was authorised by validators.
    /// - Callable by anyone.
    /// - Caller must provide `bridgeFee`.
    /// - Requires signatures from a threshold validators at proof.validatorSetId.
    /// - Requires proof is not older than `proofTTL` eras
    /// - Halts on failure
    ///
    /// @dev Parameters:
    /// - preimage: the unhashed message data packed wide w source, dest, validatorSetId & eventId e.g. `abi.encode(source, dest, message, validatorSetId, eventId);`
    /// - proof: Signed witness material generated by proving 'message'
    ///     - v,r,s are sparse arrays expected to align w public key in 'validators'
    ///     - i.e. v[i], r[i], s[i] matches the i-th validator[i]
    function _verifyMessage(bytes memory preimage, EventProof calldata proof)
        internal
    {
        // gas savings
        uint256 _eventId = proof.eventId;
        uint32 _validatorSetId = proof.validatorSetId;
        address[] memory _validators = proof.validators;

        require(active, "Bridge: bridge inactive");
        require(!verifiedEventIds[_eventId], "Bridge: eventId replayed");
        require(
            _validatorSetId <= activeValidatorSetId,
            "Bridge: future validator set"
        );
        require(
            activeValidatorSetId - _validatorSetId <= proofTTL,
            "Bridge: expired proof"
        );
        // audit item #1
        require(_validators.length > 0, "Bridge: invalid validator set");
        require(
            keccak256(abi.encode(_validators)) ==
                validatorSetDigests[_validatorSetId],
            "Bridge: unexpected validator digest"
        );

        bytes32 digest = keccak256(preimage);
        uint acceptanceTreshold = ((_validators.length * thresholdPercent) /
            100);
        uint witnessCount; // uint256(0)
        bytes32 ommited; // bytes32(0)

        for (uint i; i < _validators.length; ++i) {
            if (proof.r[i] != ommited) { // check signature omitted == bytes32(0)
                // check signature
                require(
                    _validators[i] == digest.recover(proof.v[i], proof.r[i], proof.s[i]),
                    "Bridge: signature invalid"
                );
                witnessCount += 1;
                // have we got proven consensus?
                if (witnessCount >= acceptanceTreshold) {
                    break;
                }
            }
        }

        require(witnessCount >= acceptanceTreshold, "Bridge: not enough signatures");
        verifiedEventIds[_eventId] = true;
    }

    /// @notice Handle a verified message provided by 'receiveMessage` to update the next validator set
    /// i.e. The bridge contract is itself a bridge app contract
    function onMessageReceived(address source, bytes calldata message)
        external
        override
    {
        require(msg.sender == address(this), "Bridge: only bridge can call");
        require(source == palletAddress, "Bridge: source must be pallet");
        (address[] memory newValidators, uint32 newValidatorSetId) = abi.decode(
            message,
            (address[], uint32)
        );
        _setValidators(newValidators, newValidatorSetId);
    }

    /// @dev Update the known validator set (must be called via 'relayMessage' with a valid proof of new validator set)
    function _setValidators(
        address[] memory newValidators,
        uint32 newValidatorSetId
    ) internal nonReentrant {
        require(newValidators.length > 0, "Bridge: empty validator set"); // also checked in _verifyMessage
        require(
            newValidatorSetId > activeValidatorSetId,
            "Bridge: validator set id replayed"
        );

        // update set digest and active id
        bytes32 validatorSetDigest = keccak256(abi.encode(newValidators));
        validatorSetDigests[newValidatorSetId] = validatorSetDigest;
        activeValidatorSetId = newValidatorSetId;

        // return accumulated fees to the sender as a reward, capped at `maxRewardPayout`
        uint reward = Math.min(address(this).balance - accumulatedMessageFees, maxRewardPayout);
        (bool sent, ) = tx.origin.call{value: reward}("");
        require(sent, "Bridge: Failed to send reward");

        emit SetValidators(validatorSetDigest, reward, newValidatorSetId);
    }

    /// @dev See {IERC165-supportsInterface}. Docs: https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IBridge).interfaceId ||
            interfaceId == type(IBridgeReceiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ============================================================================================================= //
    // ============================================== Admin functions ============================================== //
    // ============================================================================================================= //

    /// @notice force set the active validator set
    /// @dev newValidatorSetId can be equal to current activeValidatorSetId - to override current validators
    function forceActiveValidatorSet(
        address[] calldata newValidators,
        uint32 newValidatorSetId
    ) external onlyOwner {
        require(newValidators.length > 0, "Bridge: empty validator set");
        require(newValidatorSetId >= activeValidatorSetId, "Bridge: set is historic");
        bytes32 validatorSetDigest = keccak256(abi.encode(newValidators));
        validatorSetDigests[newValidatorSetId] = validatorSetDigest;
        activeValidatorSetId = newValidatorSetId;
        emit ForceSetActiveValidators(validatorSetDigest, newValidatorSetId);
    }

    /// @notice Force set a historic validator set
    /// @dev Sets older than proofTTL are not modifiable (since they cannot produce valid proofs any longer)
    function forceHistoricValidatorSet(
        address[] calldata _validators,
        uint32 validatorSetId
    ) external onlyOwner {
        require(_validators.length > 0, "Bridge: empty validator set");
        require(
            validatorSetId + proofTTL > activeValidatorSetId,
            "Bridge: set is inactive"
        );
        bytes32 validatorSetDigest = keccak256(abi.encode(_validators));
        validatorSetDigests[validatorSetId] = validatorSetDigest;
        emit ForceSetHistoricValidators(validatorSetDigest, validatorSetId);
    }

    /// @notice Set the TTL for historic validator set proofs
    function setProofTTL(uint256 _proofTTL) external onlyOwner {
        proofTTL = _proofTTL;
        emit ProofTTLUpdated(_proofTTL);
    }

    /// @notice Set the max reward payout for `setValidator` incentive
    function setMaxRewardPayout(uint256 _maxRewardPayout) external onlyOwner {
        maxRewardPayout = _maxRewardPayout;
        emit MaxRewardPayoutUpdated(_maxRewardPayout);
    }

    /// @notice Set the sentEventId for the contract to start with
    function setSentEventId(uint _newId) external onlyOwner {
        sentEventId = _newId;
        emit SentEventIdUpdated(_newId);
    }

    /// @notice Set the fee for verify messages
    function setBridgeFee(uint256 _bridgeFee) external onlyOwner {
        bridgeFee = _bridgeFee;
        emit BridgeFeeUpdated(_bridgeFee);
    }

    /// @notice Set the threshold % required for proof verification
    function setThreshold(uint256 _thresholdPercent) external onlyOwner {
        require(_thresholdPercent <= 100, "Bridge: percent must be <= 100");
        thresholdPercent = _thresholdPercent;
        emit ThresholdUpdated(_thresholdPercent);
    }

    /// @notice Set the pallet address
    function setPalletAddress(address _palletAddress) external onlyOwner {
        palletAddress = _palletAddress;
        emit PalletAddressUpdated(_palletAddress);
    }

    /// @notice Activate/deactivate the bridge
    function setActive(bool _active) external onlyOwner {
        active = _active;
        emit BridgeActiveUpdated(_active);
    }

    /// @dev Reset max message length
    function setMaxMessageLength(uint256 _maxMessageLength) external onlyOwner {
        maxMessageLength = _maxMessageLength;
        emit MaxMessageLengthUpdated(_maxMessageLength);
    }

    /// @dev Endow the contract with ether
    function endow() external payable {
        require(msg.value > 0, "Bridge: must endow nonzero");
        emit Endowed(msg.value);
    }

    /// @dev Owner can withdraw ether from the contract (primarily to support contract upgradability)
    function withdrawAll(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent,) = _to.call{value: balance}("");
        require(sent, "Bridge: failed to send Ether");
        emit EtherWithdrawn(_to, balance);
    }

    /// @dev Set _sendMessageFee
    function setSendMessageFee(uint256 _fee) external onlyOwner {
        _sendMessageFee = _fee;
        emit SendMessageFeeUpdated(_fee);
    }

    /// @dev Owner can withdraw accumulates msg fees from the contract
    function withdrawMsgFees(address payable _to, uint256 _amount) public onlyOwner {
        accumulatedMessageFees -= _amount; // prevent re-entrancy protection
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Bridge: Failed to send msg fees");
        emit WithdrawnMessageFees(_to, _amount);
    }
}