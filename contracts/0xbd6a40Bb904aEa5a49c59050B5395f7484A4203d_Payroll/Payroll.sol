/**
 *Submitted for verification at Etherscan.io on 2019-11-12
*/

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/IRelayRecipient.sol

pragma solidity ^0.5.0;

/*
 * @dev Interface for a contract that will be called via the GSN from RelayHub.
 */
contract IRelayRecipient {
    /**
     * @dev Returns the address of the RelayHub instance this recipient interacts with.
     */
    function getHubAddr() public view returns (address);

    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

    function preRelayedCall(bytes calldata context) external returns (bytes32);

    function postRelayedCall(bytes calldata context, bool success, uint actualCharge, bytes32 preRetVal) external;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/bouncers/GSNBouncerBase.sol

pragma solidity ^0.5.0;


/*
 * @dev Base contract used to implement GSNBouncers.
 *
 * > This contract does not perform all required tasks to implement a GSN
 * recipient contract: end users should use `GSNRecipient` instead.
 */
contract GSNBouncerBase is IRelayRecipient {
    uint256 constant private RELAYED_CALL_ACCEPTED = 0;
    uint256 constant private RELAYED_CALL_REJECTED = 11;

    // How much gas is forwarded to postRelayedCall
    uint256 constant internal POST_RELAYED_CALL_MAX_GAS = 100000;

    // Base implementations for pre and post relayedCall: only RelayHub can invoke them, and data is forwarded to the
    // internal hook.

    /**
     * @dev See `IRelayRecipient.preRelayedCall`.
     *
     * This function should not be overriden directly, use `_preRelayedCall` instead.
     *
     * * Requirements:
     *
     * - the caller must be the `RelayHub` contract.
     */
    function preRelayedCall(bytes calldata context) external returns (bytes32) {
        require(msg.sender == getHubAddr(), "GSNBouncerBase: caller is not RelayHub");
        return _preRelayedCall(context);
    }

    /**
     * @dev See `IRelayRecipient.postRelayedCall`.
     *
     * This function should not be overriden directly, use `_postRelayedCall` instead.
     *
     * * Requirements:
     *
     * - the caller must be the `RelayHub` contract.
     */
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external {
        require(msg.sender == getHubAddr(), "GSNBouncerBase: caller is not RelayHub");
        _postRelayedCall(context, success, actualCharge, preRetVal);
    }

    /**
     * @dev Return this in acceptRelayedCall to proceed with the execution of a relayed call. Note that this contract
     * will be charged a fee by RelayHub
     */
    function _approveRelayedCall() internal pure returns (uint256, bytes memory) {
        return _approveRelayedCall("");
    }

    /**
     * @dev See `GSNBouncerBase._approveRelayedCall`.
     *
     * This overload forwards `context` to _preRelayedCall and _postRelayedCall.
     */
    function _approveRelayedCall(bytes memory context) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_ACCEPTED, context);
    }

    /**
     * @dev Return this in acceptRelayedCall to impede execution of a relayed call. No fees will be charged.
     */
    function _rejectRelayedCall(uint256 errorCode) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_REJECTED + errorCode, "");
    }

    // Empty hooks for pre and post relayed call: users only have to define these if they actually use them.

    function _preRelayedCall(bytes memory) internal returns (bytes32) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _postRelayedCall(bytes memory, bool, uint256, bytes32) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /*
     * @dev Calculates how much RelaHub will charge a recipient for using `gas` at a `gasPrice`, given a relayer's
     * `serviceFee`.
     */
    function _computeCharge(uint256 gas, uint256 gasPrice, uint256 serviceFee) internal pure returns (uint256) {
        // The fee is expressed as a percentage. E.g. a value of 40 stands for a 40% fee, so the recipient will be
        // charged for 1.4 times the spent amount.
        return (gas * gasPrice * (100 + serviceFee)) / 100;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol

pragma solidity ^0.5.2;

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/bouncers/GSNBouncerSignature.sol

pragma solidity ^0.5.0;




contract GSNBouncerSignature is Initializable, GSNBouncerBase {
    using ECDSA for bytes32;

    // We use a random storage slot to allow proxy contracts to enable GSN support in an upgrade without changing their
    // storage layout. This value is calculated as: keccak256('gsn.bouncer.signature.trustedSigner'), minus 1.
    bytes32 constant private TRUSTED_SIGNER_STORAGE_SLOT = 0xe7b237a4017a399d277819456dce32c2356236bbc518a6d84a9a8d1cfdf1e9c5;

    enum GSNBouncerSignatureErrorCodes {
        INVALID_SIGNER
    }

    function initialize(address trustedSigner) public initializer {
        _setTrustedSigner(trustedSigner);
    }

    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256
    )
        external
        view
        returns (uint256, bytes memory)
    {
        bytes memory blob = abi.encodePacked(
            relay,
            from,
            encodedFunction,
            transactionFee,
            gasPrice,
            gasLimit,
            nonce, // Prevents replays on RelayHub
            getHubAddr(), // Prevents replays in multiple RelayHubs
            address(this) // Prevents replays in multiple recipients
        );
        if (keccak256(blob).toEthSignedMessageHash().recover(approvalData) == _getTrustedSigner()) {
            return _approveRelayedCall();
        } else {
            return _rejectRelayedCall(uint256(GSNBouncerSignatureErrorCodes.INVALID_SIGNER));
        }
    }

    function _getTrustedSigner() private view returns (address trustedSigner) {
      bytes32 slot = TRUSTED_SIGNER_STORAGE_SLOT;
      // solhint-disable-next-line no-inline-assembly
      assembly {
        trustedSigner := sload(slot)
      }
    }

    function _setTrustedSigner(address trustedSigner) private {
      bytes32 slot = TRUSTED_SIGNER_STORAGE_SLOT;
      // solhint-disable-next-line no-inline-assembly
      assembly {
        sstore(slot, trustedSigner)
      }
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they not should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, with should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/GSNContext.sol

pragma solidity ^0.5.0;



/*
 * @dev Enables GSN support on `Context` contracts by recognizing calls from
 * RelayHub and extracting the actual sender and call data from the received
 * calldata.
 *
 * > This contract does not perform all required tasks to implement a GSN
 * recipient contract: end users should use `GSNRecipient` instead.
 */
contract GSNContext is Initializable, Context {
    // We use a random storage slot to allow proxy contracts to enable GSN support in an upgrade without changing their
    // storage layout. This value is calculated as: keccak256('gsn.relayhub.address'), minus 1.
    bytes32 private constant RELAY_HUB_ADDRESS_STORAGE_SLOT = 0x06b7792c761dcc05af1761f0315ce8b01ac39c16cc934eb0b2f7a8e71414f262;

    event RelayHubChanged(address indexed oldRelayHub, address indexed newRelayHub);

    function initialize() public initializer {
        _upgradeRelayHub(0xD216153c06E857cD7f72665E0aF1d7D82172F494);
    }

    function _getRelayHub() internal view returns (address relayHub) {
        bytes32 slot = RELAY_HUB_ADDRESS_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            relayHub := sload(slot)
        }
    }

    function _upgradeRelayHub(address newRelayHub) internal {
        address currentRelayHub = _getRelayHub();
        require(newRelayHub != address(0), "GSNContext: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNContext: new RelayHub is the current one");

        emit RelayHubChanged(currentRelayHub, newRelayHub);

        bytes32 slot = RELAY_HUB_ADDRESS_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newRelayHub)
        }
    }

    // Overrides for Context's functions: when called from RelayHub, sender and
    // data require some pre-processing: the actual sender is stored at the end
    // of the call data, which in turns means it needs to be removed from it
    // when handling said data.

    function _msgSender() internal view returns (address) {
        if (msg.sender != _getRelayHub()) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

    function _msgData() internal view returns (bytes memory) {
        if (msg.sender != _getRelayHub()) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

    function _getRelayedCallSender() private pure returns (address result) {
        // We need to read 20 bytes (an address) located at array index msg.data.length - 20. In memory, the array
        // is prefixed with a 32-byte length value, so we first add 32 to get the memory read index. However, doing
        // so would leave the address in the upper 20 bytes of the 32-byte word, which is inconvenient and would
        // require bit shifting. We therefore subtract 12 from the read index so the address lands on the lower 20
        // bytes. This can always be done due to the 32-byte prefix.

        // The final memory read index is msg.data.length - 20 + 32 - 12 = msg.data.length. Using inline assembly is the
        // easiest/most-efficient way to perform this operation.

        // These fields are not accessible from assembly
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
        // RelayHub appends the sender address at the end of the calldata, so in order to retrieve the actual msg.data,
        // we must strip the last 20 bytes (length of an address type) from it.

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/IRelayHub.sol

pragma solidity ^0.5.0;

contract IRelayHub {
    // Relay management

    // Add stake to a relay and sets its unstakeDelay.
    // If the relay does not exist, it is created, and the caller
    // of this function becomes its owner. If the relay already exists, only the owner can call this function. A relay
    // cannot be its own owner.
    // All Ether in this function call will be added to the relay's stake.
    // Its unstake delay will be assigned to unstakeDelay, but the new value must be greater or equal to the current one.
    // Emits a Staked event.
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

    // Emited when a relay's stake or unstakeDelay are increased
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

    // Registers the caller as a relay.
    // The relay must be staked for, and not be a contract (i.e. this function must be called directly from an EOA).
    // Emits a RelayAdded event.
    // This function can be called multiple times, emitting new RelayAdded events. Note that the received transactionFee
    // is not enforced by relayCall.
    function registerRelay(uint256 transactionFee, string memory url) public;

    // Emitted when a relay is registered or re-registerd. Looking at these events (and filtering out RelayRemoved
    // events) lets a client discover the list of available relays.
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

    // Removes (deregisters) a relay. Unregistered (but staked for) relays can also be removed. Can only be called by
    // the owner of the relay. After the relay's unstakeDelay has elapsed, unstake will be callable.
    // Emits a RelayRemoved event.
    function removeRelayByOwner(address relay) public;

    // Emitted when a relay is removed (deregistered). unstakeTime is the time when unstake will be callable.
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

    // Deletes the relay from the system, and gives back its stake to the owner. Can only be called by the relay owner,
    // after unstakeDelay has elapsed since removeRelayByOwner was called.
    // Emits an Unstaked event.
    function unstake(address relay) public;

    // Emitted when a relay is unstaked for, including the returned stake.
    event Unstaked(address indexed relay, uint256 stake);

    // States a relay can be in
    enum RelayState {
        Unknown, // The relay is unknown to the system: it has never been staked for
        Staked, // The relay has been staked for, but it is not yet active
        Registered, // The relay has registered itself, and is active (can relay calls)
        Removed    // The relay has been removed by its owner and can no longer relay calls. It must wait for its unstakeDelay to elapse before it can unstake
    }

    // Returns a relay's status. Note that relays can be deleted when unstaked or penalized.
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

    // Balance management

    // Deposits ether for a contract, so that it can receive (and pay for) relayed transactions. Unused balance can only
    // be withdrawn by the contract itself, by callingn withdraw.
    // Emits a Deposited event.
    function depositFor(address target) public payable;

    // Emitted when depositFor is called, including the amount and account that was funded.
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

    // Returns an account's deposits. These can be either a contnract's funds, or a relay owner's revenue.
    function balanceOf(address target) external view returns (uint256);

    // Withdraws from an account's balance, sending it back to it. Relay owners call this to retrieve their revenue, and
    // contracts can also use it to reduce their funding.
    // Emits a Withdrawn event.
    function withdraw(uint256 amount, address payable dest) public;

    // Emitted when an account withdraws funds from RelayHub.
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

    // Relaying

    // Check if the RelayHub will accept a relayed operation. Multiple things must be true for this to happen:
    //  - all arguments must be signed for by the sender (from)
    //  - the sender's nonce must be the current one
    //  - the recipient must accept this transaction (via acceptRelayedCall)
    // Returns a PreconditionCheck value (OK when the transaction can be relayed), or a recipient-specific error code if
    // it returns one in acceptRelayedCall.
    function canRelay(
        address relay,
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public view returns (uint256 status, bytes memory recipientContext);

    // Preconditions for relaying, checked by canRelay and returned as the corresponding numeric values.
    enum PreconditionCheck {
        OK,                         // All checks passed, the call can be relayed
        WrongSignature,             // The transaction to relay is not signed by requested sender
        WrongNonce,                 // The provided nonce has already been used by the sender
        AcceptRelayedCallReverted,  // The recipient rejected this call via acceptRelayedCall
        InvalidRecipientStatusCode  // The recipient returned an invalid (reserved) status code
    }

    // Relays a transaction. For this to suceed, multiple conditions must be met:
    //  - canRelay must return PreconditionCheck.OK
    //  - the sender must be a registered relay
    //  - the transaction's gas price must be larger or equal to the one that was requested by the sender
    //  - the transaction must have enough gas to not run out of gas if all internal transactions (calls to the
    // recipient) use all gas available to them
    //  - the recipient must have enough balance to pay the relay for the worst-case scenario (i.e. when all gas is
    // spent)
    //
    // If all conditions are met, the call will be relayed and the recipient charged. preRelayedCall, the encoded
    // function and postRelayedCall will be called in order.
    //
    // Arguments:
    //  - from: the client originating the request
    //  - recipient: the target IRelayRecipient contract
    //  - encodedFunction: the function call to relay, including data
    //  - transactionFee: fee (%) the relay takes over actual gas cost
    //  - gasPrice: gas price the client is willing to pay
    //  - gasLimit: gas to forward when calling the encoded function
    //  - nonce: client's nonce
    //  - signature: client's signature over all previous params, plus the relay and RelayHub addresses
    //  - approvalData: dapp-specific data forwared to acceptRelayedCall. This value is *not* verified by the Hub, but
    //    it still can be used for e.g. a signature.
    //
    // Emits a TransactionRelayed event.
    function relayCall(
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public;

    // Emitted when an attempt to relay a call failed. This can happen due to incorrect relayCall arguments, or the
    // recipient not accepting the relayed call. The actual relayed call was not executed, and the recipient not charged.
    // The reason field contains an error code: values 1-10 correspond to PreconditionCheck entries, and values over 10
    // are custom recipient error codes returned from acceptRelayedCall.
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

    // Emitted when a transaction is relayed. Note that the actual encoded function might be reverted: this will be
    // indicated in the status field.
    // Useful when monitoring a relay's operation and relayed calls to a contract.
    // Charge is the ether value deducted from the recipient's balance, paid to the relay's owner.
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

    // Reason error codes for the TransactionRelayed event
    enum RelayCallStatus {
        OK,                      // The transaction was successfully relayed and execution successful - never included in the event
        RelayedCallFailed,       // The transaction was relayed, but the relayed call failed
        PreRelayedFailed,        // The transaction was not relayed due to preRelatedCall reverting
        PostRelayedFailed,       // The transaction was relayed and reverted due to postRelatedCall reverting
        RecipientBalanceChanged  // The transaction was relayed and reverted due to the recipient's balance changing
    }

    // Returns how much gas should be forwarded to a call to relayCall, in order to relay a transaction that will spend
    // up to relayedCallStipend gas.
    function requiredGas(uint256 relayedCallStipend) public view returns (uint256);

    // Returns the maximum recipient charge, given the amount of gas forwarded, gas price and relay fee.
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) public view returns (uint256);

    // Relay penalization. Any account can penalize relays, removing them from the system immediately, and rewarding the
    // reporter with half of the relay's stake. The other half is burned so that, even if the relay penalizes itself, it
    // still loses half of its stake.

    // Penalize a relay that signed two transactions using the same nonce (making only the first one valid) and
    // different data (gas price, gas limit, etc. may be different). The (unsigned) transaction data and signature for
    // both transactions must be provided.
    function penalizeRepeatedNonce(bytes memory unsignedTx1, bytes memory signature1, bytes memory unsignedTx2, bytes memory signature2) public;

    // Penalize a relay that sent a transaction that didn't target RelayHub's registerRelay or relayCall.
    function penalizeIllegalTransaction(bytes memory unsignedTx, bytes memory signature) public;

    event Penalized(address indexed relay, address sender, uint256 amount);

    function getNonce(address from) external view returns (uint256);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol

pragma solidity ^0.5.0;






/*
 * @dev Base GSN recipient contract, adding the recipient interface and enabling
 * GSN support. Not all interface methods are implemented, derived contracts
 * must do so themselves.
 */
contract GSNRecipient is Initializable, IRelayRecipient, GSNContext, GSNBouncerBase {
    function initialize() public initializer {
        GSNContext.initialize();
    }

    function getHubAddr() public view returns (address) {
        return _getRelayHub();
    }

    // This function is view for future-proofing, it may require reading from
    // storage in the future.
    function relayHubVersion() public view returns (string memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return "1.0.0";
    }

    function _withdrawDeposits(uint256 amount, address payable payee) internal {
        IRelayHub(_getRelayHub()).withdraw(amount, payee);
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.2;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard is Initializable {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }

    uint256[50] private ______gap;
}

// File: @sablier/shared-contracts/compound/CarefulMath.sol

pragma solidity ^0.5.8;

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// File: @sablier/shared-contracts/compound/Exponential.sol

pragma solidity ^0.5.8;


/**
 * @title Exponential module for storing fixed-decision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa; //TODO: Add some simple tests and this in another PR yo.
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }
}

// File: @sablier/shared-contracts/interfaces/ICERC20.sol

pragma solidity 0.5.11;

/**
 * @title CERC20 interface
 * @author Sablier
 * @dev See https://compound.finance/developers
 */
interface ICERC20 {
    function balanceOf(address who) external view returns (uint256);

    function isCToken() external view returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOfUnderlying(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: @sablier/shared-contracts/lifecycle/OwnableWithoutRenounce.sol

pragma solidity 0.5.11;



/**
 * @title OwnableWithoutRenounce
 * @author Sablier
 * @dev Fork of OpenZeppelin's Ownable contract, which provides basic authorization control, but with
 *  the `renounceOwnership` function removed to avoid fat-finger errors.
 *  We inherit from `Context` to keep this contract compatible with the Gas Station Network.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/ownership/Ownable.sol
 * See https://forum.openzeppelin.com/t/contract-request-ownable-without-renounceownership/1400
 * See https://docs.openzeppelin.com/contracts/2.x/gsn#_msg_sender_and_msg_data
 */
contract OwnableWithoutRenounce is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol

pragma solidity ^0.5.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: @sablier/shared-contracts/lifecycle/PauserRoleWithoutRenounce.sol

pragma solidity ^0.5.0;




/**
 * @title PauserRoleWithoutRenounce
 * @author Sablier
 * @notice Fork of OpenZeppelin's PauserRole, but with the `renouncePauser` function removed to avoid fat-finger errors.
 *  We inherit from `Context` to keep this contract compatible with the Gas Station Network.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/access/roles/PauserRole.sol
 */

contract PauserRoleWithoutRenounce is Initializable, Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    function initialize(address sender) public initializer {
        if (!isPauser(sender)) {
            _addPauser(sender);
        }
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }

    uint256[50] private ______gap;
}

// File: @sablier/shared-contracts/lifecycle/PausableWithoutRenounce.sol

pragma solidity 0.5.11;




/**
 * @title PausableWithoutRenounce
 * @author Sablier
 * @notice Fork of OpenZeppelin's Pausable, a contract module which allows children to implement an
 *  emergency stop mechanism that can be triggered by an authorized account, but with the `renouncePauser`
 *  function removed to avoid fat-finger errors.
 *  We inherit from `Context` to keep this contract compatible with the Gas Station Network.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/lifecycle/Pausable.sol
 * See https://docs.openzeppelin.com/contracts/2.x/gsn#_msg_sender_and_msg_data
 */
contract PausableWithoutRenounce is Initializable, Context, PauserRoleWithoutRenounce {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    function initialize(address sender) public initializer {
        PauserRoleWithoutRenounce.initialize(sender);
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @sablier/protocol/contracts/interfaces/ICTokenManager.sol

pragma solidity 0.5.11;

/**
 * @title CTokenManager Interface
 * @author Sablier
 */
interface ICTokenManager {
    /**
     * @notice Emits when the owner discards a cToken.
     */
    event DiscardCToken(address indexed tokenAddress);

    /**
     * @notice Emits when the owner whitelists a cToken.
     */
    event WhitelistCToken(address indexed tokenAddress);

    function whitelistCToken(address tokenAddress) external;

    function discardCToken(address tokenAddress) external;

    function isCToken(address tokenAddress) external view returns (bool);
}

// File: @sablier/protocol/contracts/interfaces/IERC1620.sol

pragma solidity 0.5.11;

/**
 * @title ERC-1620 Money Streaming Standard
 * @author Paul Razvan Berg - <[email protected]>
 * @dev See https://eips.ethereum.org/EIPS/eip-1620
 */
interface IERC1620 {
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

    /**
     * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
     */
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 balance,
            uint256 rate
        );

    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId, uint256 funds) external returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);
}

// File: @sablier/protocol/contracts/Types.sol

pragma solidity 0.5.11;


/**
 * @title Sablier Types
 * @author Sablier
 */
library Types {
    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
    }

    struct CompoundingStreamVars {
        Exponential.Exp exchangeRateInitial;
        Exponential.Exp senderShare;
        Exponential.Exp recipientShare;
        bool isEntity;
    }
}

// File: @sablier/protocol/contracts/Sablier.sol

pragma solidity 0.5.11;










/**
 * @title Sablier's Money Streaming
 * @author Sablier
 */
contract Sablier is IERC1620, OwnableWithoutRenounce, PausableWithoutRenounce, Exponential, ReentrancyGuard {
    /*** Storage Properties ***/

    /**
     * @notice In Exp terms, 1e18 is 1, or 100%
     */
    uint256 constant hundredPercent = 1e18;

    /**
     * @notice In Exp terms, 1e16 is 0.01, or 1%
     */
    uint256 constant onePercent = 1e16;

    /**
     * @notice Stores information about the initial state of the underlying of the cToken.
     */
    mapping(uint256 => Types.CompoundingStreamVars) private compoundingStreamsVars;

    /**
     * @notice An instance of CTokenManager, responsible for whitelisting and discarding cTokens.
     */
    ICTokenManager public cTokenManager;

    /**
     * @notice The amount of interest has been accrued per token address.
     */
    mapping(address => uint256) private earnings;

    /**
     * @notice The percentage fee charged by the contract on the accrued interest.
     */
    Exp public fee;

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;

    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Types.Stream) private streams;

    /*** Events ***/

    /**
     * @notice Emits when a compounding stream is successfully created.
     */
    event CreateCompoundingStream(
        uint256 indexed streamId,
        uint256 exchangeRate,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    );

    /**
     * @notice Emits when the owner discards a cToken.
     */
    event PayInterest(
        uint256 indexed streamId,
        uint256 senderInterest,
        uint256 recipientInterest,
        uint256 sablierInterest
    );

    /**
     * @notice Emits when the owner takes the earnings.
     */
    event TakeEarnings(address indexed tokenAddress, uint256 indexed amount);

    /**
     * @notice Emits when the owner updates the percentage fee.
     */
    event UpdateFee(uint256 indexed fee);

    /*** Modifiers ***/

    /**
     * @dev Throws if the caller is not the sender of the recipient of the stream.
     */
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender || msg.sender == streams[streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

    /**
     * @dev Throws if the id does not point to a valid stream.
     */
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

    /**
     * @dev Throws if the id does not point to a valid compounding stream.
     */
    modifier compoundingStreamExists(uint256 streamId) {
        require(compoundingStreamsVars[streamId].isEntity, "compounding stream does not exist");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor(address cTokenManagerAddress) public {
        require(cTokenManagerAddress != address(0x00), "cTokenManager contract is the zero address");
        OwnableWithoutRenounce.initialize(msg.sender);
        PausableWithoutRenounce.initialize(msg.sender);
        cTokenManager = ICTokenManager(cTokenManagerAddress);
        nextStreamId = 1;
    }

    /*** Owner Functions ***/

    struct UpdateFeeLocalVars {
        MathError mathErr;
        uint256 feeMantissa;
    }

    /**
     * @notice Updates the Sablier fee.
     * @dev Throws if the caller is not the owner of the contract.
     *  Throws if `feePercentage` is not lower or equal to 100.
     * @param feePercentage The new fee as a percentage.
     */
    function updateFee(uint256 feePercentage) external onlyOwner {
        require(feePercentage <= 100, "fee percentage higher than 100%");
        UpdateFeeLocalVars memory vars;

        /* `feePercentage` will be stored as a mantissa, so we scale it up by one percent in Exp terms. */
        (vars.mathErr, vars.feeMantissa) = mulUInt(feePercentage, onePercent);
        /*
         * `mulUInt` can only return MathError.INTEGER_OVERFLOW but we control `onePercent`
         * and we know `feePercentage` is maximum 100.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        fee = Exp({ mantissa: vars.feeMantissa });
        emit UpdateFee(feePercentage);
    }

    struct TakeEarningsLocalVars {
        MathError mathErr;
    }

    /**
     * @notice Withdraws the earnings for the given token address.
     * @dev Throws if `amount` exceeds the available balance.
     * @param tokenAddress The address of the token to withdraw earnings for.
     * @param amount The amount of tokens to withdraw.
     */
    function takeEarnings(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(cTokenManager.isCToken(tokenAddress), "cToken is not whitelisted");
        require(amount > 0, "amount is zero");
        require(earnings[tokenAddress] >= amount, "amount exceeds the available balance");

        TakeEarningsLocalVars memory vars;
        (vars.mathErr, earnings[tokenAddress]) = subUInt(earnings[tokenAddress], amount);
        /*
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `earnings[tokenAddress]`
         * is at least as big as `amount`.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        emit TakeEarnings(tokenAddress, amount);
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "token transfer failure");
    }

    /*** View Functions ***/

    /**
     * @notice Returns the compounding stream with all its properties.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream to query.
     * @return The stream object.
     */
    function getStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
    }

    /**
     * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
     *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
     *  `startTime`, it returns 0.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for whom to query the delta.
     * @return The time delta in seconds.
     */
    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
        Types.Stream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    struct BalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }

    /**
     * @notice Returns the available funds for the given stream id and address.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for whom to query the balance.
     * @param who The address for whom to query the balance.
     * @return The total funds allocated to `who` as uint256.
     */
    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {
        Types.Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        (vars.mathErr, vars.recipientBalance) = mulUInt(delta, stream.ratePerSecond);
        require(vars.mathErr == MathError.NO_ERROR, "recipient balance calculation error");

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        if (stream.deposit > stream.remainingBalance) {
            (vars.mathErr, vars.withdrawalAmount) = subUInt(stream.deposit, stream.remainingBalance);
            assert(vars.mathErr == MathError.NO_ERROR);
            (vars.mathErr, vars.recipientBalance) = subUInt(vars.recipientBalance, vars.withdrawalAmount);
            /* `withdrawalAmount` cannot and should not be bigger than `recipientBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
        }

        if (who == stream.recipient) return vars.recipientBalance;
        if (who == stream.sender) {
            (vars.mathErr, vars.senderBalance) = subUInt(stream.remainingBalance, vars.recipientBalance);
            /* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
            return vars.senderBalance;
        }
        return 0;
    }

    /**
     * @notice Checks if the given id points to a compounding stream.
     * @param streamId The id of the compounding stream to check.
     * @return bool true=it is compounding stream, otherwise false.
     */
    function isCompoundingStream(uint256 streamId) public view returns (bool) {
        return compoundingStreamsVars[streamId].isEntity;
    }

    /**
     * @notice Returns the compounding stream object with all its properties.
     * @dev Throws if the id does not point to a valid compounding stream.
     * @param streamId The id of the compounding stream to query.
     * @return The compounding stream object.
     */
    function getCompoundingStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        compoundingStreamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            uint256 exchangeRateInitial,
            uint256 senderSharePercentage,
            uint256 recipientSharePercentage
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
        exchangeRateInitial = compoundingStreamsVars[streamId].exchangeRateInitial.mantissa;
        senderSharePercentage = compoundingStreamsVars[streamId].senderShare.mantissa;
        recipientSharePercentage = compoundingStreamsVars[streamId].recipientShare.mantissa;
    }

    struct InterestOfLocalVars {
        MathError mathErr;
        Exp exchangeRateDelta;
        Exp underlyingInterest;
        Exp netUnderlyingInterest;
        Exp senderUnderlyingInterest;
        Exp recipientUnderlyingInterest;
        Exp sablierUnderlyingInterest;
        Exp senderInterest;
        Exp recipientInterest;
        Exp sablierInterest;
    }

    /**
     * @notice Computes the interest accrued by keeping the amount of tokens in the contract. Returns (0, 0, 0) if
     *  the stream is not a compounding stream.
     * @dev Throws if there is a math error. We do not assert the calculations which involve the current
     *  exchange rate, because we can't know what value we'll get back from the cToken contract.
     * @return The interest accrued by the sender, the recipient and sablier, respectively, as uint256s.
     */
    function interestOf(uint256 streamId, uint256 amount)
        public
        streamExists(streamId)
        returns (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest)
    {
        if (!compoundingStreamsVars[streamId].isEntity) {
            return (0, 0, 0);
        }
        Types.Stream memory stream = streams[streamId];
        Types.CompoundingStreamVars memory compoundingStreamVars = compoundingStreamsVars[streamId];
        InterestOfLocalVars memory vars;

        /*
         * The exchange rate delta is a key variable, since it leads us to how much interest has been earned
         * since the compounding stream was created.
         */
        Exp memory exchangeRateCurrent = Exp({ mantissa: ICERC20(stream.tokenAddress).exchangeRateCurrent() });
        if (exchangeRateCurrent.mantissa <= compoundingStreamVars.exchangeRateInitial.mantissa) {
            return (0, 0, 0);
        }
        (vars.mathErr, vars.exchangeRateDelta) = subExp(exchangeRateCurrent, compoundingStreamVars.exchangeRateInitial);
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Calculate how much interest has been earned by holding `amount` in the smart contract. */
        (vars.mathErr, vars.underlyingInterest) = mulScalar(vars.exchangeRateDelta, amount);
        require(vars.mathErr == MathError.NO_ERROR, "interest calculation error");

        /* Calculate our share from that interest. */
        if (fee.mantissa == hundredPercent) {
            (vars.mathErr, vars.sablierInterest) = divExp(vars.underlyingInterest, exchangeRateCurrent);
            require(vars.mathErr == MathError.NO_ERROR, "sablier interest conversion error");
            return (0, 0, truncate(vars.sablierInterest));
        } else if (fee.mantissa == 0) {
            vars.sablierUnderlyingInterest = Exp({ mantissa: 0 });
            vars.netUnderlyingInterest = vars.underlyingInterest;
        } else {
            (vars.mathErr, vars.sablierUnderlyingInterest) = mulExp(vars.underlyingInterest, fee);
            require(vars.mathErr == MathError.NO_ERROR, "sablier interest calculation error");

            /* Calculate how much interest is left for the sender and the recipient. */
            (vars.mathErr, vars.netUnderlyingInterest) = subExp(
                vars.underlyingInterest,
                vars.sablierUnderlyingInterest
            );
            /*
             * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `sablierUnderlyingInterest`
             * is less or equal than `underlyingInterest`, because we control the value of `fee`.
             */
            assert(vars.mathErr == MathError.NO_ERROR);
        }

        /* Calculate the sender's share of the interest. */
        (vars.mathErr, vars.senderUnderlyingInterest) = mulExp(
            vars.netUnderlyingInterest,
            compoundingStreamVars.senderShare
        );
        require(vars.mathErr == MathError.NO_ERROR, "sender interest calculation error");

        /* Calculate the recipient's share of the interest. */
        (vars.mathErr, vars.recipientUnderlyingInterest) = subExp(
            vars.netUnderlyingInterest,
            vars.senderUnderlyingInterest
        );
        /*
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `senderUnderlyingInterest`
         * is less or equal than `netUnderlyingInterest`, because `senderShare` is bounded between 1e16 and 1e18.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Convert the interest to the equivalent cToken denomination. */
        (vars.mathErr, vars.senderInterest) = divExp(vars.senderUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "sender interest conversion error");

        (vars.mathErr, vars.recipientInterest) = divExp(vars.recipientUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "recipient interest conversion error");

        (vars.mathErr, vars.sablierInterest) = divExp(vars.sablierUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "sablier interest conversion error");

        /* Truncating the results means losing everything on the last 1e18 positions of the mantissa */
        return (truncate(vars.senderInterest), truncate(vars.recipientInterest), truncate(vars.sablierInterest));
    }

    /**
     * @notice Returns the amount of interest that has been accrued for the given token address.
     * @param tokenAddress The address of the token to get the earnings for.
     * @return The amount of interest as uint256.
     */
    function getEarnings(address tokenAddress) external view returns (uint256) {
        require(cTokenManager.isCToken(tokenAddress), "token is not cToken");
        return earnings[tokenAddress];
    }

    /*** Public Effects & Interactions Functions ***/

    struct CreateStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 ratePerSecond;
    }

    /**
     * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Throws if paused.
     *  Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the deposit is 0.
     *  Throws if the start time is before `block.timestamp`.
     *  Throws if the stop time is before the start time.
     *  Throws if the duration calculation has a math error.
     *  Throws if the deposit is smaller than the duration.
     *  Throws if the deposit is not a multiple of the duration.
     *  Throws if the rate calculation has a math error.
     *  Throws if the next stream id calculation has a math error.
     *  Throws if the contract is not allowed to transfer enough tokens.
     *  Throws if there is a token transfer failure.
     * @param recipient The address towards which the money is streamed.
     * @param deposit The amount of money to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @return The uint256 id of the newly created stream.
     */
    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        public
        whenNotPaused
        returns (uint256)
    {
        require(recipient != address(0x00), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(deposit > 0, "deposit is zero");
        require(startTime >= block.timestamp, "start time before block.timestamp");
        require(stopTime > startTime, "stop time before the start time");

        CreateStreamLocalVars memory vars;
        (vars.mathErr, vars.duration) = subUInt(stopTime, startTime);
        /* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Without this, the rate per second would be zero. */
        require(deposit >= vars.duration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        require(deposit % vars.duration == 0, "deposit not multiple of time delta");

        (vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);
        /* `divUInt` can only return MathError.DIVISION_BY_ZERO but we know `duration` is not zero. */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        streams[streamId] = Types.Stream({
            remainingBalance: deposit,
            deposit: deposit,
            isEntity: true,
            ratePerSecond: vars.ratePerSecond,
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            stopTime: stopTime,
            tokenAddress: tokenAddress
        });

        /* Increment the next stream id. */
        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
        require(vars.mathErr == MathError.NO_ERROR, "next stream id calculation error");

        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), deposit), "token transfer failure");
        emit CreateStream(streamId, msg.sender, recipient, deposit, tokenAddress, startTime, stopTime);
        return streamId;
    }

    struct CreateCompoundingStreamLocalVars {
        MathError mathErr;
        uint256 shareSum;
        uint256 underlyingBalance;
        uint256 senderShareMantissa;
        uint256 recipientShareMantissa;
    }

    /**
     * @notice Creates a new compounding stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Inherits all security checks from `createStream`.
     *  Throws if the cToken is not whitelisted.
     *  Throws if the sender share percentage and the recipient share percentage do not sum up to 100.
     *  Throws if the the sender share mantissa calculation has a math error.
     *  Throws if the the recipient share mantissa calculation has a math error.
     * @param recipient The address towards which the money is streamed.
     * @param deposit The amount of money to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @param senderSharePercentage The sender's share of the interest, as a percentage.
     * @param recipientSharePercentage The recipient's share of the interest, as a percentage.
     * @return The uint256 id of the newly created compounding stream.
     */
    function createCompoundingStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    ) external whenNotPaused returns (uint256) {
        require(cTokenManager.isCToken(tokenAddress), "cToken is not whitelisted");
        CreateCompoundingStreamLocalVars memory vars;

        /* Ensure that the interest shares sum up to 100%. */
        (vars.mathErr, vars.shareSum) = addUInt(senderSharePercentage, recipientSharePercentage);
        require(vars.mathErr == MathError.NO_ERROR, "share sum calculation error");
        require(vars.shareSum == 100, "shares do not sum up to 100");

        uint256 streamId = createStream(recipient, deposit, tokenAddress, startTime, stopTime);

        /*
         * `senderSharePercentage` and `recipientSharePercentage` will be stored as mantissas, so we scale them up
         * by one percent in Exp terms.
         */
        (vars.mathErr, vars.senderShareMantissa) = mulUInt(senderSharePercentage, onePercent);
        /*
         * `mulUInt` can only return MathError.INTEGER_OVERFLOW but we control `onePercent` and
         * we know `senderSharePercentage` is maximum 100.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr, vars.recipientShareMantissa) = mulUInt(recipientSharePercentage, onePercent);
        /*
         * `mulUInt` can only return MathError.INTEGER_OVERFLOW but we control `onePercent` and
         * we know `recipientSharePercentage` is maximum 100.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Create and store the compounding stream vars. */
        uint256 exchangeRateCurrent = ICERC20(tokenAddress).exchangeRateCurrent();
        compoundingStreamsVars[streamId] = Types.CompoundingStreamVars({
            exchangeRateInitial: Exp({ mantissa: exchangeRateCurrent }),
            isEntity: true,
            recipientShare: Exp({ mantissa: vars.recipientShareMantissa }),
            senderShare: Exp({ mantissa: vars.senderShareMantissa })
        });

        emit CreateCompoundingStream(streamId, exchangeRateCurrent, senderSharePercentage, recipientSharePercentage);
        return streamId;
    }

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to withdraw tokens from.
     * @param amount The amount of tokens to withdraw.
     * @return bool true=success, otherwise false.
     */
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        require(amount > 0, "amount is zero");
        Types.Stream memory stream = streams[streamId];
        uint256 balance = balanceOf(streamId, stream.recipient);
        require(balance >= amount, "amount exceeds the available balance");

        if (!compoundingStreamsVars[streamId].isEntity) {
            withdrawFromStreamInternal(streamId, amount);
        } else {
            withdrawFromCompoundingStreamInternal(streamId, amount);
        }
        return true;
    }

    /**
     * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to cancel.
     * @return bool true=success, otherwise false.
     */
    function cancelStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        if (!compoundingStreamsVars[streamId].isEntity) {
            cancelStreamInternal(streamId);
        } else {
            cancelCompoundingStreamInternal(streamId);
        }
        return true;
    }

    /*** Internal Effects & Interactions Functions ***/

    struct WithdrawFromStreamInternalLocalVars {
        MathError mathErr;
    }

    /**
     * @notice Makes the withdrawal to the recipient of the stream.
     * @dev If the stream balance has been depleted to 0, the stream object is deleted
     *  to save gas and optimise contract storage.
     *  Throws if the stream balance calculation has a math error.
     *  Throws if there is a token transfer failure.
     */
    function withdrawFromStreamInternal(uint256 streamId, uint256 amount) internal {
        Types.Stream memory stream = streams[streamId];
        WithdrawFromStreamInternalLocalVars memory vars;
        (vars.mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, amount);
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`. See the `require` check in `withdrawFromInternal`.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        require(IERC20(stream.tokenAddress).transfer(stream.recipient, amount), "token transfer failure");
        emit WithdrawFromStream(streamId, stream.recipient, amount);
    }

    struct WithdrawFromCompoundingStreamInternalLocalVars {
        MathError mathErr;
        uint256 amountWithoutSenderInterest;
        uint256 netWithdrawalAmount;
    }

    /**
     * @notice Withdraws to the recipient's account and pays the accrued interest to all parties.
     * @dev If the stream balance has been depleted to 0, the stream object to save gas and optimise
     *  contract storage.
     *  Throws if there is a math error.
     *  Throws if there is a token transfer failure.
     */
    function withdrawFromCompoundingStreamInternal(uint256 streamId, uint256 amount) internal {
        Types.Stream memory stream = streams[streamId];
        WithdrawFromCompoundingStreamInternalLocalVars memory vars;

        /* Calculate the interest earned by each party for keeping `stream.balance` in the smart contract. */
        (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest) = interestOf(streamId, amount);

        /*
         * Calculate the net withdrawal amount by subtracting `senderInterest` and `sablierInterest`.
         * Because the decimal points are lost when we truncate Exponentials, the recipient will implicitly earn
         * `recipientInterest` plus a tiny-weeny amount of interest, max 2e-8 in cToken denomination.
         */
        (vars.mathErr, vars.amountWithoutSenderInterest) = subUInt(amount, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "amount without sender interest calculation error");
        (vars.mathErr, vars.netWithdrawalAmount) = subUInt(vars.amountWithoutSenderInterest, sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net withdrawal amount calculation error");

        /* Subtract `amount` from the remaining balance of the stream. */
        (vars.mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, amount);
        require(vars.mathErr == MathError.NO_ERROR, "balance subtraction calculation error");

        /* Delete the objects from storage if the remaining balance has been depleted to 0. */
        if (streams[streamId].remainingBalance == 0) {
            delete streams[streamId];
            delete compoundingStreamsVars[streamId];
        }

        /* Add the sablier interest to the earnings for this cToken. */
        (vars.mathErr, earnings[stream.tokenAddress]) = addUInt(earnings[stream.tokenAddress], sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "earnings addition calculation error");

        /* Transfer the tokens to the sender and the recipient. */
        ICERC20 cToken = ICERC20(stream.tokenAddress);
        if (senderInterest > 0)
            require(cToken.transfer(stream.sender, senderInterest), "sender token transfer failure");
        require(cToken.transfer(stream.recipient, vars.netWithdrawalAmount), "recipient token transfer failure");

        emit WithdrawFromStream(streamId, stream.recipient, vars.netWithdrawalAmount);
        emit PayInterest(streamId, senderInterest, recipientInterest, sablierInterest);
    }

    /**
     * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
     * @dev The stream and compounding stream vars objects get deleted to save gas
     *  and optimise contract storage.
     *  Throws if there is a token transfer failure.
     */
    function cancelStreamInternal(uint256 streamId) internal {
        Types.Stream memory stream = streams[streamId];
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        delete streams[streamId];

        IERC20 token = IERC20(stream.tokenAddress);
        if (recipientBalance > 0)
            require(token.transfer(stream.recipient, recipientBalance), "recipient token transfer failure");
        if (senderBalance > 0) require(token.transfer(stream.sender, senderBalance), "sender token transfer failure");

        emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
    }

    struct CancelCompoundingStreamInternal {
        MathError mathErr;
        uint256 netSenderBalance;
        uint256 recipientBalanceWithoutSenderInterest;
        uint256 netRecipientBalance;
    }

    /**
     * @notice Cancels the stream, transfers the tokens back on a pro rata basis and pays the accrued
     * interest to all parties.
     * @dev Importantly, the money that has not been streamed yet is not considered chargeable.
     *  All the interest generated by that underlying will be returned to the sender.
     *  Throws if there is a math error.
     *  Throws if there is a token transfer failure.
     */
    function cancelCompoundingStreamInternal(uint256 streamId) internal {
        Types.Stream memory stream = streams[streamId];
        CancelCompoundingStreamInternal memory vars;

        /*
         * The sender gets back all the money that has not been streamed so far. By that, we mean both
         * the underlying amount and the interest generated by it.
         */
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        /* Calculate the interest earned by each party for keeping `recipientBalance` in the smart contract. */
        (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest) = interestOf(
            streamId,
            recipientBalance
        );

        /*
         * We add `senderInterest` to `senderBalance` to compute the net balance for the sender.
         * After this, the rest of the function is similar to `withdrawFromCompoundingStreamInternal`, except
         * we add the sender's share of the interest generated by `recipientBalance` to `senderBalance`.
         */
        (vars.mathErr, vars.netSenderBalance) = addUInt(senderBalance, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net sender balance calculation error");

        /*
         * Calculate the net withdrawal amount by subtracting `senderInterest` and `sablierInterest`.
         * Because the decimal points are lost when we truncate Exponentials, the recipient will implicitly earn
         * `recipientInterest` plus a tiny-weeny amount of interest, max 2e-8 in cToken denomination.
         */
        (vars.mathErr, vars.recipientBalanceWithoutSenderInterest) = subUInt(recipientBalance, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "recipient balance without sender interest calculation error");
        (vars.mathErr, vars.netRecipientBalance) = subUInt(vars.recipientBalanceWithoutSenderInterest, sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net recipient balance calculation error");

        /* Add the sablier interest to the earnings attributed to this cToken. */
        (vars.mathErr, earnings[stream.tokenAddress]) = addUInt(earnings[stream.tokenAddress], sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "earnings addition calculation error");

        /* Delete the objects from storage. */
        delete streams[streamId];
        delete compoundingStreamsVars[streamId];

        /* Transfer the tokens to the sender and the recipient. */
        IERC20 token = IERC20(stream.tokenAddress);
        if (vars.netSenderBalance > 0)
            require(token.transfer(stream.sender, vars.netSenderBalance), "sender token transfer failure");
        if (vars.netRecipientBalance > 0)
            require(token.transfer(stream.recipient, vars.netRecipientBalance), "recipient token transfer failure");

        emit CancelStream(streamId, stream.sender, stream.recipient, vars.netSenderBalance, vars.netRecipientBalance);
        emit PayInterest(streamId, senderInterest, recipientInterest, sablierInterest);
    }
}

// File: contracts/Payroll.sol

pragma solidity 0.5.11;










/**
 * @title Payroll Proxy
 * @author Sablier
 */
contract Payroll is Initializable, OwnableWithoutRenounce, Exponential, GSNRecipient, GSNBouncerSignature {
    /*** Storage Properties ***/

    /**
     * @notice Container for salary information
     * @member company The address of the company which funded this salary
     * @member isEntity bool true=object exists, otherwise false
     * @member streamId The id of the stream in the Sablier contract
     */
    struct Salary {
        address company;
        bool isEntity;
        uint256 streamId;
    }

    /**
     * @notice Counter for new salary ids.
     */
    uint256 public nextSalaryId;

    /**
     * @notice Whitelist of accounts able to call the withdrawal function for a given stream so
     *  employees don't have to pay gas.
     */
    mapping(address => mapping(uint256 => bool)) public relayers;

    /**
     * @notice An instance of Sablier, the contract responsible for creating, withdrawing from and cancelling streams.
     */
    Sablier public sablier;

    /**
     * @notice The salary objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Salary) private salaries;

    /*** Events ***/

    /**
     * @notice Emits when a salary is successfully created.
     */
    event CreateSalary(uint256 indexed salaryId, uint256 indexed streamId, address indexed company);

    /**
     * @notice Emits when the employee withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromSalary(uint256 indexed salaryId, uint256 indexed streamId, address indexed company);

    /**
     * @notice Emits when a salary is successfully cancelled and both parties get their pro rata
     *  share of the available funds.
     */
    event CancelSalary(uint256 indexed salaryId, uint256 indexed streamId, address indexed company);

    /**
     * @dev Throws if the caller is not the company or the employee.
     */
    modifier onlyCompanyOrEmployee(uint256 salaryId) {
        Salary memory salary = salaries[salaryId];
        (, address employee, , , , , , ) = sablier.getStream(salary.streamId);
        require(
            _msgSender() == salary.company || _msgSender() == employee,
            "caller is not the company or the employee"
        );
        _;
    }

    /**
     * @dev Throws if the caller is not the employee or an approved relayer.
     */
    modifier onlyEmployeeOrRelayer(uint256 salaryId) {
        Salary memory salary = salaries[salaryId];
        (, address employee, , , , , , ) = sablier.getStream(salary.streamId);
        require(
            _msgSender() == employee || relayers[_msgSender()][salaryId],
            "caller is not the employee or a relayer"
        );
        _;
    }

    /**
     * @dev Throws if the id does not point to a valid salary.
     */
    modifier salaryExists(uint256 salaryId) {
        require(salaries[salaryId].isEntity, "salary does not exist");
        _;
    }

    /*** Contract Logic Starts Here ***/

    /**
     * @notice Only called once after the contract is deployed. We ask for the owner and the signer address
     *  to be specified as parameters to avoid handling `msg.sender` directly.
     * @dev The `initializer` modifier ensures that the function can only be called once.
     * @param ownerAddress The address of the contract owner.
     * @param signerAddress The address of the account able to authorise relayed transactions.
     * @param sablierAddress The address of the Sablier contract.
     */
    function initialize(address ownerAddress, address signerAddress, address sablierAddress) public initializer {
        require(ownerAddress != address(0x00), "owner is the zero address");
        require(signerAddress != address(0x00), "signer is the zero address");
        require(sablierAddress != address(0x00), "sablier contract is the zero address");
        OwnableWithoutRenounce.initialize(ownerAddress);
        GSNRecipient.initialize();
        GSNBouncerSignature.initialize(signerAddress);
        sablier = Sablier(sablierAddress);
        nextSalaryId = 1;
    }

    /*** Admin ***/

    /**
     * @notice Whitelists a relayer to process withdrawals so the employee doesn't have to pay gas.
     * @dev Throws if the caller is not the owner of the contract.
     *  Throws if the id does not point to a valid salary.
     *  Throws if the relayer is whitelisted.
     * @param relayer The address of the relayer account.
     * @param salaryId The id of the salary to whitelist the relayer for.
     */
    function whitelistRelayer(address relayer, uint256 salaryId) external onlyOwner salaryExists(salaryId) {
        require(!relayers[relayer][salaryId], "relayer is whitelisted");
        relayers[relayer][salaryId] = true;
    }

    /**
     * @notice Discard a previously whitelisted relayer to prevent them from processing withdrawals.
     * @dev Throws if the caller is not the owner of the contract.
     *  Throws if the relayer is not whitelisted.
     * @param relayer The address of the relayer account.
     * @param salaryId The id of the salary to discard the relayer for.
     */
    function discardRelayer(address relayer, uint256 salaryId) external onlyOwner {
        require(relayers[relayer][salaryId], "relayer is not whitelisted");
        relayers[relayer][salaryId] = false;
    }

    /*** View Functions ***/

    /**
     * @dev Called by {IRelayHub} to validate if this recipient accepts being charged for a relayed call. Note that the
     * recipient will be charged regardless of the execution result of the relayed call (i.e. if it reverts or not).
     *
     * The relay request was originated by `from` and will be served by `relay`. `encodedFunction` is the relayed call
     * calldata, so its first four bytes are the function selector. The relayed call will be forwarded `gasLimit` gas,
     * and the transaction executed with a gas price of at least `gasPrice`. `relay`'s fee is `transactionFee`, and the
     * recipient will be charged at most `maxPossibleCharge` (in wei). `nonce` is the sender's (`from`) nonce for
     * replay attack protection in {IRelayHub}, and `approvalData` is a optional parameter that can be used to hold
     * a signature over all or some of the previous values.
     *
     * Returns a tuple, where the first value is used to indicate approval (0) or rejection (custom non-zero error code,
     * values 1 to 10 are reserved) and the second one is data to be passed to the other {IRelayRecipient} functions.
     *
     * {acceptRelayedCall} is called with 50k gas: if it runs out during execution, the request will be considered
     * rejected. A regular revert will also trigger a rejection.
     */
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256
    ) external view returns (uint256, bytes memory) {
        /**
         * `nonce` prevents replays on RelayHub
         * `getHubAddr` prevents replays in multiple RelayHubs
         * `address(this)` prevents replays in multiple recipients
         */
        bytes memory blob = abi.encodePacked(
            relay,
            from,
            encodedFunction,
            transactionFee,
            gasPrice,
            gasLimit,
            nonce,
            getHubAddr(),
            address(this)
        );
        if (keccak256(blob).toEthSignedMessageHash().recover(approvalData) == owner()) {
            return _approveRelayedCall();
        } else {
            return _rejectRelayedCall(uint256(GSNBouncerSignatureErrorCodes.INVALID_SIGNER));
        }
    }

    /**
     * @notice Returns the salary object with all its properties.
     * @dev Throws if the id does not point to a valid salary.
     * @param salaryId The id of the salary to query.
     * @return The salary object.
     */
    function getSalary(uint256 salaryId)
        public
        view
        salaryExists(salaryId)
        returns (
            address company,
            address employee,
            uint256 salary,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 rate
        )
    {
        company = salaries[salaryId].company;
        (, employee, salary, tokenAddress, startTime, stopTime, remainingBalance, rate) = sablier.getStream(
            salaries[salaryId].streamId
        );
    }

    /*** Public Effects & Interactions Functions ***/

    struct CreateSalaryLocalVars {
        MathError mathErr;
    }

    /**
     * @notice Creates a new salary funded by `msg.sender` and paid towards `employee`.
     * @dev Throws if there is a math error.
     *  Throws if there is a token transfer failure.
     * @param employee The address of the employee who receives the salary.
     * @param salary The amount of tokens to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @return The uint256 id of the newly created salary.
     */
    function createSalary(address employee, uint256 salary, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 salaryId)
    {
        /* Transfer the tokens to this contract. */
        require(IERC20(tokenAddress).transferFrom(_msgSender(), address(this), salary), "token transfer failure");

        /* Approve the Sablier contract to spend from our tokens. */
        require(IERC20(tokenAddress).approve(address(sablier), salary), "token approval failure");

        /* Create the stream. */
        uint256 streamId = sablier.createStream(employee, salary, tokenAddress, startTime, stopTime);
        salaryId = nextSalaryId;
        salaries[nextSalaryId] = Salary({ company: _msgSender(), isEntity: true, streamId: streamId });

        /* Increment the next salary id. */
        CreateSalaryLocalVars memory vars;
        (vars.mathErr, nextSalaryId) = addUInt(nextSalaryId, uint256(1));
        require(vars.mathErr == MathError.NO_ERROR, "next stream id calculation error");

        emit CreateSalary(salaryId, streamId, _msgSender());
    }

    /**
     * @notice Creates a new compounding salary funded by `msg.sender` and paid towards `employee`.
     * @dev There's a bit of redundancy between `createSalary` and this function, but one has to
     *  call `sablier.createStream` and the other `sablier.createCompoundingStream`, so it's not
     *  worth it to run DRY code.
     *  Throws if there is a math error.
     *  Throws if there is a token transfer failure.
     * @param employee The address of the employee who receives the salary.
     * @param salary The amount of tokens to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @param senderSharePercentage The sender's share of the interest, as a percentage.
     * @param recipientSharePercentage The sender's share of the interest, as a percentage.
     * @return The uint256 id of the newly created compounding salary.
     */
    function createCompoundingSalary(
        address employee,
        uint256 salary,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    ) external returns (uint256 salaryId) {
        /* Transfer the tokens to this contract. */
        require(IERC20(tokenAddress).transferFrom(_msgSender(), address(this), salary), "token transfer failure");

        /* Approve the Sablier contract to spend from our tokens. */
        require(IERC20(tokenAddress).approve(address(sablier), salary), "token approval failure");

        /* Create the stream. */
        uint256 streamId = sablier.createCompoundingStream(
            employee,
            salary,
            tokenAddress,
            startTime,
            stopTime,
            senderSharePercentage,
            recipientSharePercentage
        );
        salaryId = nextSalaryId;
        salaries[nextSalaryId] = Salary({ company: _msgSender(), isEntity: true, streamId: streamId });

        /* Increment the next salary id. */
        CreateSalaryLocalVars memory vars;
        (vars.mathErr, nextSalaryId) = addUInt(nextSalaryId, uint256(1));
        require(vars.mathErr == MathError.NO_ERROR, "next stream id calculation error");

        /* We don't emit a different event for compounding salaries because we emit CreateCompoundingStream. */
        emit CreateSalary(salaryId, streamId, _msgSender());
    }

    struct CancelSalaryLocalVars {
        MathError mathErr;
        uint256 netCompanyBalance;
    }

    /**
     * @notice Withdraws from the contract to the employee's account.
     * @dev Throws if the id does not point to a valid salary.
     *  Throws if the caller is not the employee or a relayer.
     *  Throws if there is a token transfer failure.
     * @param salaryId The id of the salary to withdraw from.
     * @param amount The amount of tokens to withdraw.
     * @return bool true=success, false otherwise.
     */
    function withdrawFromSalary(uint256 salaryId, uint256 amount)
        external
        salaryExists(salaryId)
        onlyEmployeeOrRelayer(salaryId)
        returns (bool success)
    {
        Salary memory salary = salaries[salaryId];
        success = sablier.withdrawFromStream(salary.streamId, amount);
        emit WithdrawFromSalary(salaryId, salary.streamId, salary.company);
    }

    /**
     * @notice Cancels the salary and transfers the tokens back on a pro rata basis.
     * @dev Throws if the id does not point to a valid salary.
     *  Throws if the caller is not the company or the employee.
     *  Throws if there is a token transfer failure.
     * @param salaryId The id of the salary to cancel.
     * @return bool true=success, false otherwise.
     */
    function cancelSalary(uint256 salaryId)
        external
        salaryExists(salaryId)
        onlyCompanyOrEmployee(salaryId)
        returns (bool success)
    {
        Salary memory salary = salaries[salaryId];

        /* We avoid storing extraneous data twice, so we read the token address from Sablier. */
        (, address employee, , address tokenAddress, , , , ) = sablier.getStream(salary.streamId);
        uint256 companyBalance = sablier.balanceOf(salary.streamId, address(this));

        /**
         * The company gets all the money that has not been streamed yet, plus all the interest earned by what's left.
         * Not all streams are compounding and `companyBalance` coincides with `netCompanyBalance` then.
         */
        CancelSalaryLocalVars memory vars;
        if (!sablier.isCompoundingStream(salary.streamId)) {
            vars.netCompanyBalance = companyBalance;
        } else {
            uint256 employeeBalance = sablier.balanceOf(salary.streamId, employee);
            (uint256 companyInterest, , ) = sablier.interestOf(salary.streamId, employeeBalance);
            (vars.mathErr, vars.netCompanyBalance) = addUInt(companyBalance, companyInterest);
            require(vars.mathErr == MathError.NO_ERROR, "net company balance calculation error");
        }

        /* Delete the salary object to save gas. */
        delete salaries[salaryId];
        success = sablier.cancelStream(salary.streamId);

        /* Transfer the tokens to the company. */
        if (vars.netCompanyBalance > 0)
            require(
                IERC20(tokenAddress).transfer(salary.company, vars.netCompanyBalance),
                "company token transfer failure"
            );

        emit CancelSalary(salaryId, salary.streamId, salary.company);
    }
}