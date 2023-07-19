// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {ECDSA, EIP712} from "openzeppelin-contracts/utils/cryptography/EIP712.sol";
import {ERC2771Context} from "openzeppelin-contracts/metatx/ERC2771Context.sol";
import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

using EnumerableSet for EnumerableSet.AddressSet;

/// @notice Description of a call.
/// @param target The called address.
/// @param data The calldata to be used for the call.
/// @param value The value of the call.
struct Call {
    address target;
    bytes data;
    uint256 value;
}

/// @notice A generic call executor increasing flexibility of other smart contracts' APIs.
/// It offers 3 main features, which can be mixed and matched for even more flexibility:
/// - Authorizing addresses to act on behalf of other addresses
/// - Support for EIP-712 messages
/// - Batching calls
///
/// `Caller` adds these features to the APIs of all smart contracts reading the message
/// sender passed as per ERC-2771 and accepting this contract as a trusted forwarder.
/// To all other contracts `Caller` adds a feature of batching calls
/// for all functions tolerating `msg.sender` being an instance of `Caller`.
///
/// Usage examples:
/// - Batching sequences of calls to a contract.
/// The contract API may consist of many functions which need to be called in sequence,
/// but it may not offer a composite functions performing exactly that sequence.
/// It's expensive, slow and unreliable to create a separate transaction for each step.
/// To solve that problem create a batch of calls and submit it to `callBatched`.
/// - Batching sequences of calls to multiple contracts.
/// It's a common pattern to submit an ERC-2612 permit to approve a smart contract
/// to spend the user's ERC-20 tokens before running that contract's logic.
/// Unfortunately unless the contract's API accepts signed messages for the token it requires
/// creating two separate transactions making it as inconvenient as a regular approval.
/// The solution is again to use `callBatched` because it can call multiple contracts.
/// Just create a batch first calling the ERC-20 contract and then the contract needing the tokens.
/// - Setting up a proxy address.
/// Sometimes a secure but inconvenient to use address like a cold wallet
/// or a multisig needs to have a proxy or an operator.
/// That operator is temporarily trusted, but later it must be revoked or rotated.
/// To achieve this first `authorize` the proxy using the safe address and then use that proxy
/// to act on behalf of the secure address using `callAs`.
/// Later, when the proxy address needs to be revoked, either the secure address or the proxy itself
/// can `unauthorize` the proxy address and maybe `authorize` another address.
/// - Setting up operations callable by others.
/// Some operations may benefit from being callable either by trusted addresses or by anybody.
/// To achieve this deploy a smart contract executing these operations
/// via `callAs` and, if you need that too, implementing a custom authorization.
/// Finally, `authorize` this smart contract to act on behalf of your address.
/// - Batching dynamic sequences of calls.
/// Some operations need to react dynamically to the state of the blockchain.
/// For example an unknown amount of funds is retrieved from a smart contract,
/// which then needs to be dynamically split and used for different purposes.
/// To do this, first deploy a smart contract performing that logic.
/// Next, call `callBatched` which first calls `authorize` on the `Caller` itself authorizing
/// the new contract to perform `callAs`, then calls that contract and finally `unauthorize`s it.
/// This way the contract can perform any logic it needs on behalf of your address, but only once.
/// - Gasless transactions.
/// It's an increasingly common pattern to use smart contracts without necessarily spending Ether.
/// This is achieved with gasless transactions where the wallet signs an ERC-712 message
/// and somebody else submits the actual transaction executing what the message requests.
/// It may be executed by another wallet or by an operator
/// expecting to be repaid for the spent Ether in other assets.
/// You can achieve this with `callSigned`, which allows anybody
/// to execute a call on behalf of the signer of a message.
/// `Caller` doesn't deal with gas, so if you're using a gasless network,
/// it may require you to specify the gas needed for the entire call execution.
/// - Executing batched calls with authorization or signature.
/// You can use both `callAs` and `callSigned` to call `Caller` itself,
/// which in turn can execute batched calls on behalf of the authorizing or signing address.
/// It also applies to `authorize` and `unauthorize`, they too can be called using
/// `callAs`, `callSigned` or `callBatched`.
contract Caller is EIP712("Caller", "1"), ERC2771Context(address(this)) {
    /// @notice The maximum increase of the nonce possible by calling `setNonce`.
    uint256 public constant MAX_NONCE_INCREASE = 10 ** 9;
    string internal constant CALL_SIGNED_TYPE_NAME = "CallSigned("
        "address sender,address target,bytes data,uint256 value,uint256 nonce,uint256 deadline)";
    bytes32 internal immutable callSignedTypeHash = keccak256(bytes(CALL_SIGNED_TYPE_NAME));

    /// @notice Each sender's set of address authorized to make calls on its behalf.
    // slither-disable-next-line naming-convention
    mapping(address sender => AddressSetClearable) internal _authorized;
    /// @notice The nonce which needs to be used in the next EIP-712 message signed by the address.
    mapping(address sender => uint256) public nonce;

    /// @notice A clearable set of addresses.
    /// @param clears Number of performed clears. Increase to clear.
    /// @param addressSets The set of addresses.
    /// Always use the set under the key equal to the current value of `clears`.
    struct AddressSetClearable {
        uint256 clears;
        mapping(uint256 clears => EnumerableSet.AddressSet) addressSets;
    }

    /// @notice Emitted when `authorized` makes a call on behalf of `sender`.
    /// @param sender The address on behalf of which a call was made.
    /// @param authorized The address making the call on behalf of `sender`.
    event CalledAs(address indexed sender, address indexed authorized);

    /// @notice Emitted when granting the authorization
    /// of an address to make calls on behalf of the `sender`.
    /// @param sender The authorizing address.
    /// @param authorized The authorized address.
    event Authorized(address indexed sender, address indexed authorized);

    /// @notice Emitted when revoking the authorization
    /// of an address to make calls on behalf of the `sender`.
    /// @param sender The authorizing address.
    /// @param unauthorized The authorized address.
    event Unauthorized(address indexed sender, address indexed unauthorized);

    /// @notice Emitted when revoking all authorizations to make calls on behalf of the `sender`.
    /// @param sender The authorizing address.
    event UnauthorizedAll(address indexed sender);

    /// @notice Emitted when a signed call is made on behalf of `sender`.
    /// @param sender The address on behalf of which a call was made.
    /// @param nonce The used nonce.
    event CalledSigned(address indexed sender, uint256 nonce);

    /// @notice Emitted when a new nonce is set for `sender`.
    /// @param sender The address for which the nonce was set.
    /// @param newNonce The new nonce.
    event NonceSet(address indexed sender, uint256 newNonce);

    /// @notice Grants the authorization of an address to make calls on behalf of the sender.
    /// @param user The authorized address.
    function authorize(address user) public {
        address sender = _msgSender();
        require(_getAuthorizedSet(sender).add(user), "Address already is authorized");
        emit Authorized(sender, user);
    }

    /// @notice Revokes the authorization of an address to make calls on behalf of the sender.
    /// @param user The unauthorized address.
    function unauthorize(address user) public {
        address sender = _msgSender();
        require(_getAuthorizedSet(sender).remove(user), "Address is not authorized");
        emit Unauthorized(sender, user);
    }

    /// @notice Revokes all authorizations to make calls on behalf of the sender.
    function unauthorizeAll() public {
        address sender = _msgSender();
        _authorized[sender].clears++;
        emit UnauthorizedAll(sender);
    }

    /// @notice Checks if an address is authorized to make calls on behalf of a sender.
    /// @param sender The authorizing address.
    /// @param user The potentially authorized address.
    /// @return authorized True if `user` is authorized.
    function isAuthorized(address sender, address user) public view returns (bool authorized) {
        return _getAuthorizedSet(sender).contains(user);
    }

    /// @notice Returns all the addresses authorized to make calls on behalf of a sender.
    /// @param sender The authorizing address.
    /// @return authorized The list of all the authorized addresses, ordered arbitrarily.
    /// The list's order may change when sender authorizes or unauthorizes addresses.
    function allAuthorized(address sender) public view returns (address[] memory authorized) {
        return _getAuthorizedSet(sender).values();
    }

    /// @notice Makes a call on behalf of the `sender`.
    /// Callable only by an address currently `authorize`d by the `sender`.
    /// Reverts if the call reverts or the called address is not a smart contract.
    /// This function is payable, any Ether sent to it will be passed in the call.
    /// @param sender The sender to be set as the message sender of the call as per ERC-2771.
    /// @param target The called address.
    /// @param data The calldata to be used for the call.
    /// @return returnData The data returned by the call.
    function callAs(address sender, address target, bytes calldata data)
        public
        payable
        returns (bytes memory returnData)
    {
        address authorized = _msgSender();
        require(isAuthorized(sender, authorized), "Not authorized");
        emit CalledAs(sender, authorized);
        return _call(sender, target, data, msg.value);
    }

    /// @notice Makes a call on behalf of the `sender`.
    /// Requires a `sender`'s signature of an ERC-712 message approving the call.
    /// Reverts if the call reverts or the called address is not a smart contract.
    /// This function is payable, any Ether sent to it will be passed in the call.
    /// @param sender The sender to be set as the message sender of the call as per ERC-2771.
    /// @param target The called address.
    /// @param data The calldata to be used for the call.
    /// @param deadline The timestamp until which the message signature is valid.
    /// @param r The `r` part of the compact message signature as per EIP-2098.
    /// @param sv The `sv` part of the compact message signature as per EIP-2098.
    /// @return returnData The data returned by the call.
    function callSigned(
        address sender,
        address target,
        bytes calldata data,
        uint256 deadline,
        bytes32 r,
        bytes32 sv
    ) public payable returns (bytes memory returnData) {
        // slither-disable-next-line timestamp
        require(block.timestamp <= deadline, "Execution deadline expired");
        uint256 currNonce = nonce[sender]++;
        bytes32 executeHash = keccak256(
            abi.encode(
                callSignedTypeHash, sender, target, keccak256(data), msg.value, currNonce, deadline
            )
        );
        address signer = ECDSA.recover(_hashTypedDataV4(executeHash), r, sv);
        require(signer == sender, "Invalid signature");
        emit CalledSigned(sender, currNonce);
        return _call(sender, target, data, msg.value);
    }

    /// @notice Sets the new nonce for the sender.
    /// @param newNonce The new nonce.
    /// It must be larger than the current nonce but by no more than MAX_NONCE_INCREASE.
    function setNonce(uint256 newNonce) public {
        address sender = _msgSender();
        uint256 currNonce = nonce[sender];
        require(newNonce > currNonce, "Nonce not increased");
        require(newNonce <= currNonce + MAX_NONCE_INCREASE, "Nonce increased by too much");
        nonce[sender] = newNonce;
        emit NonceSet(sender, newNonce);
    }

    /// @notice Executes a batch of calls.
    /// The caller will be set as the message sender of all the calls as per ERC-2771.
    /// Reverts if any of the calls reverts or any of the called addresses is not a smart contract.
    /// This function is payable, any Ether sent to it can be used in the batched calls.
    /// Any unused Ether will stay in this contract,
    /// anybody will be able to use it in future calls to `callBatched`.
    /// @param calls The calls to perform.
    /// @return returnData The data returned by each of the calls.
    function callBatched(Call[] calldata calls)
        public
        payable
        returns (bytes[] memory returnData)
    {
        returnData = new bytes[](calls.length);
        address sender = _msgSender();
        for (uint256 i = 0; i < calls.length; i++) {
            Call calldata call = calls[i];
            returnData[i] = _call(sender, call.target, call.data, call.value);
        }
    }

    /// @notice Gets the set of addresses authorized to make calls on behalf of `sender`.
    /// @param sender The authorizing address.
    /// @return authorizedSet The set of authorized addresses.
    function _getAuthorizedSet(address sender)
        internal
        view
        returns (EnumerableSet.AddressSet storage authorizedSet)
    {
        AddressSetClearable storage authorized = _authorized[sender];
        return authorized.addressSets[authorized.clears];
    }

    /// @notice Makes a call on behalf of the `sender`.
    /// Reverts if the call reverts or the called address is not a smart contract.
    /// @param sender The sender to be set as the message sender of the call as per ERC-2771.
    /// @param target The called address.
    /// @param data The calldata to be used for the call.
    /// @param value The value of the call.
    /// @return returnData The data returned by the call.
    function _call(address sender, address target, bytes calldata data, uint256 value)
        internal
        returns (bytes memory returnData)
    {
        // Encode the message sender as per ERC-2771
        return Address.functionCallWithValue(target, bytes.concat(data, bytes20(sender)), value);
    }
}