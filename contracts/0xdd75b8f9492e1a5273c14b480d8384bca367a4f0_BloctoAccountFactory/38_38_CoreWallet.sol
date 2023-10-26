// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/BytesExtractSignature.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Core Wallet
/// @notice A basic smart contract wallet with cosigner functionality. The notion of "cosigner" is
///  the simplest possible multisig solution, a two-of-two signature scheme. It devolves nicely
///  to "one-of-one" (i.e. singlesig) by simply having the cosigner set to the same value as
///  the main signer.
///
///  Most "advanced" functionality (deadman's switch, multiday recovery flows, blacklisting, etc)
///  can be implemented externally to this smart contract, either as an additional smart contract
///  (which can be tracked as a signer without cosigner, or as a cosigner) or as an off-chain flow
///  using a public/private key pair as cosigner. Of course, the basic cosigning functionality could
///  also be implemented in this way, but (A) the complexity and gas cost of two-of-two multisig (as
///  implemented here) is negligable even if you don't need the cosigner functionality, and
///  (B) two-of-two multisig (as implemented here) handles a lot of really common use cases, most
///  notably third-party gas payment and off-chain blacklisting and fraud detection.
contract CoreWallet is IERC1271 {
    using BytesExtractSignature for bytes;
    using ECDSA for bytes;

    /// @notice We require that presigned transactions use the EIP-191 signing format.
    ///  See that EIP for more info: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-191.md
    bytes1 public constant EIP191_VERSION_DATA = bytes1(0);
    bytes1 public constant EIP191_PREFIX = bytes1(0x19);

    /// @notice This is a sentinel value used to determine when a delegate is set to expose
    ///  support for an interface containing more than a single function. See `delegates` and
    ///  `setDelegate` for more information.
    address public constant COMPOSITE_PLACEHOLDER = address(1);

    /// @notice A pre-shifted "1", used to increment the authVersion, so we can "prepend"
    ///  the authVersion to an address (for lookups in the authorizations mapping)
    ///  by using the '+' operator (which is cheaper than a shift and a mask). See the
    ///  comment on the `authorizations` variable for how this is used.
    uint256 public constant AUTH_VERSION_INCREMENTOR = (1 << 160);

    /// @notice Q constant for schnorr signature verify
    uint256 internal constant Q = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    /// @notice s of signature must be less than S_MAX refer from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/f29307cfe08c7d76d96a38bf94bab5fec223c943/contracts/utils/cryptography/ECDSA.sol#L156
    bytes32 internal constant S_MAX = bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);

    /// @notice The pre-shifted authVersion (to get the current authVersion as an integer,
    ///  shift this value right by 160 bits). Starts as `1 << 160` (`AUTH_VERSION_INCREMENTOR`)
    ///  See the comment on the `authorizations` variable for how this is used.
    uint256 public authVersion;

    /// @notice A mapping containing all of the addresses that are currently authorized to manage
    ///  the assets owned by this wallet.
    ///
    ///  The keys in this mapping are authorized addresses with a version number prepended,
    ///  like so: (authVersion,96)(address,160). The current authVersion MUST BE included
    ///  for each look-up; this allows us to effectively clear the entire mapping of its
    ///  contents merely by incrementing the authVersion variable. (This is important for
    ///  the emergencyRecovery() method.) Inspired by https://ethereum.stackexchange.com/a/42540
    ///
    ///  The values in this mapping are 256bit words, whose lower 20 bytes constitute "cosigners"
    ///  for each address. If an address maps to itself, then that address is said to have no cosigner.
    ///
    ///  Addresses that map to a non-zero cosigner in the current authVersion are called
    ///  "authorized addresses".
    mapping(uint256 => uint256) public authorizations;

    // (authVersion,96)(padding_0,152)(isSchnorr,1) (authKeyIdx,6)(parity,1) -> merged_ec_pubkey_x (256)
    // isSchnorr: 1 -> schnorr, 0 -> not schnorr
    mapping(uint256 => bytes32) public mergedKeys;

    /// @notice A per-key nonce value, incremented each time a transaction is processed with that key.
    ///  Used for replay prevention. The nonce value in the transaction must exactly equal the current
    ///  nonce value in the wallet for that key. (This mirrors the way Ethereum's transaction nonce works.)
    uint256 public nonce;

    /// @notice A mapping tracking dynamically supported interfaces and their corresponding
    ///  implementation contracts. Keys are interface IDs and values are addresses of
    ///  contracts that are responsible for implementing the function corresponding to the
    ///  interface.
    ///
    ///  Delegates are added (or removed) via the `setDelegate` method after the contract is
    ///  deployed, allowing support for new interfaces to be dynamically added after deployment.
    ///  When a delegate is added, its interface ID is considered "supported" under EIP165.
    ///
    ///  For cases where an interface composed of more than a single function must be
    ///  supported, it is necessary to manually add the composite interface ID with
    ///  `setDelegate(interfaceId, COMPOSITE_PLACEHOLDER)`. Interface IDs added with the
    ///  COMPOSITE_PLACEHOLDER address are ignored when called and are only used to specify
    ///  supported interfaces.
    mapping(bytes4 => address) public delegates;

    /// @notice A special address that is authorized to call `emergencyRecovery()`. That function
    ///  resets ALL authorization for this wallet, and must therefore be treated with utmost security.
    ///  Reasonable choices for recoveryAddress include:
    ///       - the address of a private key in cold storage
    ///       - a physically secured hardware wallet
    ///       - a multisig smart contract, possibly with a time-delayed challenge period
    ///       - the zero address, if you like performing without a safety net ;-)
    address public recoveryAddress;

    /// @notice Used to track whether or not this contract instance has been initialized. This
    ///  is necessary since it is common for this wallet smart contract to be used as the "library
    ///  code" for an clone contract. See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    ///  for more information about clone contracts.
    bool public initialized;

    error ExecutionResult(bool targetSuccess);

    /// @notice Used to decorate methods that can only be called directly by the recovery address.
    modifier onlyRecoveryAddress() {
        require(msg.sender == recoveryAddress, "sender must be recovery address");
        _;
    }

    /// @notice Used to decorate the `init` function so this can only be called one time. Necessary
    ///  since this contract will often be used as a "clone". (See above.)
    modifier onlyOnce() {
        require(!initialized, "must not already be initialized");
        initialized = true;
        _;
    }

    /// @notice Used to decorate methods that can only be called indirectly via an `invoke()` method.
    ///  In practice, it means that those methods can only be called by a signer/cosigner
    ///  pair that is currently authorized. Theoretically, we could factor out the
    ///  signer/cosigner verification code and use it explicitly in this modifier, but that
    ///  would either result in duplicated code, or additional overhead in the invoke()
    ///  calls (due to the stack manipulation for calling into the shared verification function).
    ///  Doing it this way makes calling the administration functions more expensive (since they
    ///  go through a explicit call() instead of just branching within the contract), but it
    ///  makes invoke() more efficient. We assume that invoke() will be used much, much more often
    ///  than any of the administration functions.
    modifier onlyInvoked() {
        require(msg.sender == address(this), "must be called from `invoke()`");
        _;
    }

    /// @notice Emitted when an authorized address is added, removed, or modified. When an
    ///  authorized address is removed ("deauthorized"), cosigner will be address(0) in
    ///  this event.
    ///
    ///  NOTE: When emergencyRecovery() is called, all existing addresses are deauthorized
    ///  WITHOUT Authorized(addr, 0) being emitted. If you are keeping an off-chain mirror of
    ///  authorized addresses, you must also watch for EmergencyRecovery events.
    /// @dev hash is 0xf5a7f4fb8a92356e8c8c4ae7ac3589908381450500a7e2fd08c95600021ee889
    /// @param authorizedAddress the address to authorize or unauthorize
    /// @param cosigner the 2-of-2 signatory (optional).
    event Authorized(address authorizedAddress, uint256 cosigner);

    event AuthorizedMergedKey(uint8 mergedKeyIndexWithParity, bytes32 mergedKey);

    /// @notice Emitted when an emergency recovery has been performed. If this event is fired,
    ///  ALL previously authorized addresses have been deauthorized and the only authorized
    ///  address is the authorizedAddress indicated in this event.
    /// @dev hash is 0xe12d0bbeb1d06d7a728031056557140afac35616f594ef4be227b5b172a604b5
    /// @param authorizedAddress the new authorized address
    /// @param cosigner the cosigning address for `authorizedAddress`
    event EmergencyRecovery(address authorizedAddress, uint256 cosigner);

    /// @notice Emitted when the recovery address changes. Either (but not both) of the
    ///  parameters may be zero.
    /// @dev hash is 0x568ab3dedd6121f0385e007e641e74e1f49d0fa69cab2957b0b07c4c7de5abb6
    /// @param previousRecoveryAddress the previous recovery address
    /// @param newRecoveryAddress the new recovery address
    event RecoveryAddressChanged(address previousRecoveryAddress, address newRecoveryAddress);

    /// @dev Emitted when this contract receives a non-zero amount ether via the fallback function
    ///  (i.e. This event is not fired if the contract receives ether as part of a method invocation)
    /// @param from the address which sent you ether
    /// @param value the amount of ether sent
    event Received(address from, uint256 value);

    /// @notice Emitted whenever a transaction is processed successfully from this wallet. Includes
    ///  both simple send ether transactions, as well as other smart contract invocations.
    /// @dev hash is 0x101214446435ebbb29893f3348e3aae5ea070b63037a3df346d09d3396a34aee
    /// @param hash The hash of the entire operation set. 0 is returned when emitted from `invoke0()`.
    /// @param result A bitfield of the results of the operations. A bit of 0 means success, and 1 means failure.
    /// @param numOperations A count of the number of operations processed
    event InvocationSuccess(bytes32 hash, uint256 result, uint256 numOperations);

    /// @notice Emitted when a delegate is added or removed.
    /// @param interfaceId The interface ID as specified by EIP165
    /// @param delegate The address of the contract implementing the given function. If this is
    ///  COMPOSITE_PLACEHOLDER, we are indicating support for a composite interface.
    event DelegateUpdated(bytes4 interfaceId, address delegate);

    /// @notice The shared initialization code used to setup the contract state regardless of whether or
    ///  not the clone pattern is being used.
    /// @param _authorizedAddress the initial authorized address, must not be zero!
    /// @param _cosigner the initial cosigning address for `_authorizedAddress`, can be equal to `_authorizedAddress`
    /// @param _recoveryAddress the initial recovery address for the wallet, can be address(0)
    /// @param _mergedKeyIndexWithParity the corresponding index of mergedKeys = authVersion + _mergedIndex
    /// @param _mergedKey the corresponding mergedKey (using Schnorr merged key)
    function init(
        address _authorizedAddress,
        uint256 _cosigner,
        address _recoveryAddress,
        uint8 _mergedKeyIndexWithParity,
        bytes32 _mergedKey
    ) public onlyOnce {
        require(_authorizedAddress != address(0), "authorized addresses must not be zero");
        require(_authorizedAddress != _recoveryAddress, "do not use the recovery address as an authorized address");
        require(address(uint160(_cosigner)) != _recoveryAddress, "do not use the recovery address as a cosigner");
        require(address(uint160(_cosigner)) != address(0), "cosigner address must not be zero");

        recoveryAddress = _recoveryAddress;
        // set initial authorization value
        authVersion = AUTH_VERSION_INCREMENTOR;
        // add initial authorized address
        authorizations[AUTH_VERSION_INCREMENTOR + uint256(uint160(_authorizedAddress))] = _cosigner;
        mergedKeys[AUTH_VERSION_INCREMENTOR + _mergedKeyIndexWithParity] = _mergedKey;
        emit Authorized(_authorizedAddress, _cosigner);
    }

    /// @notice The shared initialization code used to setup the contract state regardless of whether or
    ///  not the clone pattern is being used.
    /// @param _authorizedAddresses the initial authorized addresses, must not be zero!
    /// @param _cosigner the initial cosigning address for `_authorizedAddress`, can be equal to `_authorizedAddress`
    /// @param _recoveryAddress the initial recovery address for the wallet, can be address(0)
    /// @param _mergedKeyIndexWithParitys the corresponding index of mergedKeys = authVersion + _mergedIndex
    /// @param _mergedKeys the corresponding mergedKey
    function init2(
        address[] calldata _authorizedAddresses,
        uint256 _cosigner,
        address _recoveryAddress,
        uint8[] calldata _mergedKeyIndexWithParitys,
        bytes32[] calldata _mergedKeys
    ) public onlyOnce {
        require(_authorizedAddresses.length != 0, "invalid authorizedAddresses array");
        require(_authorizedAddresses.length == _mergedKeyIndexWithParitys.length, "array length not match");
        require(_authorizedAddresses.length == _mergedKeys.length, "array length not match");
        require(address(uint160(_cosigner)) != address(0), "cosigner address must not be zero");
        require(address(uint160(_cosigner)) != _recoveryAddress, "do not use the recovery address as a cosigner");
        recoveryAddress = _recoveryAddress;
        // set initial authorization value
        authVersion = AUTH_VERSION_INCREMENTOR;
        for (uint256 i = 0; i < _authorizedAddresses.length; i++) {
            address _authorizedAddress = _authorizedAddresses[i];
            require(_authorizedAddress != address(0), "authorized addresses must not be zero");
            require(_authorizedAddress != _recoveryAddress, "do not use the recovery address as an authorized address");
            authorizations[AUTH_VERSION_INCREMENTOR + uint256(uint160(_authorizedAddress))] = _cosigner;
            mergedKeys[AUTH_VERSION_INCREMENTOR + _mergedKeyIndexWithParitys[i]] = _mergedKeys[i];

            emit Authorized(_authorizedAddress, _cosigner);
        }
    }

    /// @notice The fallback function, invoked whenever we receive a transaction that doesn't call any of our
    ///  named functions. In particular, this method is called when we are the target of a simple send
    ///  transaction, when someone calls a method we have dynamically added a delegate for, or when someone
    ///  tries to call a function we don't implement, either statically or dynamically.
    ///
    ///  A correct invocation of this method occurs in following case:
    ///  - someone calls a delegated function (`msg.data.length` is greater than 0 and
    ///    `delegates[msg.sig]` is set)
    ///  In all other cases, this function will revert.
    ///
    ///  NOTE: Some smart contracts send 0 eth as part of a more complex operation
    ///  (-cough- CryptoKitties -cough-); ideally, we'd `require(msg.value > 0)` here when
    ///  `msg.data.length == 0`, but to work with those kinds of smart contracts, we accept zero sends
    ///  and just skip logging in that case.
    fallback() external payable {
        if (msg.value > 0) {
            emit Received(msg.sender, msg.value);
        }

        address delegate = delegates[msg.sig];
        require(delegate > COMPOSITE_PLACEHOLDER, "invalid transaction");

        // We have found a delegate contract that is responsible for the method signature of
        // this call. Now, pass along the calldata of this CALL to the delegate contract.
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := staticcall(gas(), delegate, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            // If the delegate reverts, we revert. If the delegate does not revert, we return the data
            // returned by the delegate to the original caller.
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        if (msg.value > 0) {
            emit Received(msg.sender, msg.value);
        }
    }

    /// @notice Adds or removes dynamic support for an interface. Can be used in 3 ways:
    ///   - Add a contract "delegate" that implements a single function
    ///   - Remove delegate for a function
    ///   - Specify that an interface ID is "supported", without adding a delegate. This is
    ///     used for composite interfaces when the interface ID is not a single method ID.
    /// @dev Must be called through `invoke`
    /// @param _interfaceId The ID of the interface we are adding support for
    /// @param _delegate Either:
    ///    - the address of a contract that implements the function specified by `_interfaceId`
    ///      for adding an implementation for a single function
    ///    - 0 for removing an existing delegate
    ///    - COMPOSITE_PLACEHOLDER for specifying support for a composite interface
    function setDelegate(bytes4 _interfaceId, address _delegate) external onlyInvoked {
        delegates[_interfaceId] = _delegate;
        emit DelegateUpdated(_interfaceId, _delegate);
    }

    /// @notice Configures an authorizable address. Can be used in four ways:
    ///   - Add a new signer/cosigner pair (cosigner must be non-zero)
    ///   - Set or change the cosigner for an existing signer (if authorizedAddress != cosigner)
    ///   - Remove the cosigning requirement for a signer (if authorizedAddress == cosigner)
    ///   - Remove a signer (if cosigner == address(0))
    /// @dev Must be called through `invoke()`
    /// @param _authorizedAddress the address to configure authorization
    /// @param _cosigner the corresponding cosigning address
    /// @param _mergedIndexWithParity the corresponding index of mergedKeys = authVersion + _mergedIndex
    /// @param _mergedKey the corresponding mergedKey
    function setAuthorized(
        address _authorizedAddress,
        uint256 _cosigner,
        uint8 _mergedIndexWithParity,
        bytes32 _mergedKey
    ) external onlyInvoked {
        require(_authorizedAddress != address(0), "authorized address must not be zero");
        require(_authorizedAddress != recoveryAddress, "do not use the recovery address as an authorized address");
        require(
            (address(uint160(_cosigner)) == address(0) && _mergedKey == 0)
                || address(uint160(_cosigner)) != recoveryAddress,
            "do not use the recovery address as a cosigner"
        );

        authorizations[authVersion + uint256(uint160(_authorizedAddress))] = _cosigner;
        mergedKeys[authVersion + _mergedIndexWithParity] = _mergedKey;

        emit Authorized(_authorizedAddress, _cosigner);
    }

    /// @notice Configures an authorizable address to use a merged key.
    /// @dev Must be called through `invoke()`
    /// @param _mergedKeyIndexWithParity the merged key index
    /// @param _mergedKey the corresponding merged authorized key & cosigner key by Schnorr
    function setMergedKey(uint8 _mergedKeyIndexWithParity, bytes32 _mergedKey) external onlyInvoked {
        require((_mergedKeyIndexWithParity & 0x80) > 0, "invalid merged key index");
        mergedKeys[authVersion + _mergedKeyIndexWithParity] = _mergedKey;
        emit AuthorizedMergedKey(_mergedKeyIndexWithParity, _mergedKey);
    }

    /// @notice Performs an emergency recovery operation, removing all existing authorizations and setting
    ///  a sole new authorized address with optional cosigner. THIS IS A SCORCHED EARTH SOLUTION, and great
    ///  care should be taken to ensure that this method is never called unless it is a last resort. See the
    ///  comments above about the proper kinds of addresses to use as the recoveryAddress to ensure this method
    ///  is not trivially abused.
    /// @param _authorizedAddress the new and sole authorized address
    /// @param _cosigner the corresponding cosigner address, can be equal to _authorizedAddress
    /// @param _mergedKeyIndexWithParity the merged key index
    /// @param _mergedKey the corresponding merged authorized key & cosigner key by Schnorr
    function emergencyRecovery(
        address _authorizedAddress,
        uint256 _cosigner,
        uint8 _mergedKeyIndexWithParity,
        bytes32 _mergedKey
    ) external onlyRecoveryAddress {
        require(_authorizedAddress != address(0), "authorized address must not be zero");
        require(_authorizedAddress != recoveryAddress, "do not use the recovery address as an authorized address");
        require(address(uint160(_cosigner)) != address(0), "cosigner must not be zero");

        // Incrementing the authVersion number effectively erases the authorizations mapping. See the comments
        // on the authorizations variable (above) for more information.
        authVersion += AUTH_VERSION_INCREMENTOR;

        // Store the new signer/cosigner pair as the only remaining authorized address
        authorizations[authVersion + uint256(uint160(_authorizedAddress))] = _cosigner;
        mergedKeys[authVersion + _mergedKeyIndexWithParity] = _mergedKey;
        emit EmergencyRecovery(_authorizedAddress, _cosigner);
    }

    /// @notice same as emergencyRecovery, but with a recovery address
    /// @param _authorizedAddress the new and sole authorized address
    /// @param _cosigner the corresponding cosigner address, can be equal to _authorizedAddress
    /// @param _recoveryAddress recovery address
    /// @param _mergedKeyIndexWithParity the merged key index
    /// @param _mergedKey the corresponding merged authorized key & cosigner key by Schnorr
    function emergencyRecovery2(
        address _authorizedAddress,
        uint256 _cosigner,
        address _recoveryAddress,
        uint8 _mergedKeyIndexWithParity,
        bytes32 _mergedKey
    ) external onlyRecoveryAddress {
        require(_authorizedAddress != address(0), "authorized address must not be zero");
        require(_authorizedAddress != _recoveryAddress, "do not use the recovery address as an authorized address");
        require(address(uint160(_cosigner)) != address(0), "cosigner must not be zero");
        require(_recoveryAddress != address(0), "recovery address must not be zero");
        require(address(uint160(_cosigner)) != _recoveryAddress, "do not use the recovery address as a cosigner");

        // Incrementing the authVersion number effectively erases the authorizations mapping. See the comments
        // on the authorizations variable (above) for more information.
        authVersion += AUTH_VERSION_INCREMENTOR;

        // Store the new signer/cosigner pair as the only remaining authorized address
        authorizations[authVersion + uint256(uint160(_authorizedAddress))] = _cosigner;
        mergedKeys[authVersion + _mergedKeyIndexWithParity] = _mergedKey;
        // set new recovery address
        address previous = recoveryAddress;
        recoveryAddress = _recoveryAddress;

        emit RecoveryAddressChanged(previous, recoveryAddress);
        emit EmergencyRecovery(_authorizedAddress, _cosigner);
    }

    /// @notice Sets the recovery address, which can be zero (indicating that no recovery is possible)
    ///  Can be updated by any authorized address. This address should be set with GREAT CARE. See the
    ///  comments above about the proper kinds of addresses to use as the recoveryAddress to ensure this
    ///  mechanism is not trivially abused.
    /// @dev Must be called through `invoke()`
    /// @param _recoveryAddress the new recovery address
    function setRecoveryAddress(address _recoveryAddress) external onlyInvoked {
        require(
            address(uint160(authorizations[authVersion + uint256(uint160(_recoveryAddress))])) == address(0),
            "do not use an authorized address as the recovery address"
        );
        require(_recoveryAddress != address(0), "recovery address must not be zero");

        address previous = recoveryAddress;
        recoveryAddress = _recoveryAddress;

        emit RecoveryAddressChanged(previous, recoveryAddress);
    }

    /// @notice Allows ANY caller to recover gas by way of deleting old authorization keys after
    ///  a recovery operation. Anyone can call this method to delete the old unused storage and
    ///  get themselves a bit of gas refund in the bargin.
    /// @dev keys must be known to caller or else nothing is refunded
    /// @param _version the version of the mapping which you want to delete (unshifted)
    /// @param _keys the authorization keys to delete
    function recoverGas(uint256 _version, address[] calldata _keys) external {
        require(_version < 0xffffffffffffffffffffffff, "invalid version number");

        uint256 shiftedVersion = _version << 160;

        require(shiftedVersion < authVersion, "only recover gas from expired authVersions");

        for (uint256 i = 0; i < _keys.length; ++i) {
            delete(authorizations[shiftedVersion + uint256(uint160(_keys[i]))]);
        }
    }

    function verifySchnorr(bytes32 hash, bytes memory sig) internal view returns (bool) {
        // px := public key x-coord
        // e := schnorr signature challenge
        // s := schnorr signature
        // parity := public key y-coord parity (27 or 28)
        (bytes32 e, bytes32 s, uint8 keyIndexWithParity) = sig.extractSignature(0);
        // require(s <= S_MAX, "s of signature is too large");
        bytes32 px = mergedKeys[authVersion + uint256(keyIndexWithParity)];
        uint8 parity = (keyIndexWithParity & 0x1) + 27;

        bytes32 sp = bytes32(Q - mulmod(uint256(s), uint256(px), Q));
        bytes32 ep = bytes32(Q - mulmod(uint256(e), uint256(px), Q));

        require(sp != 0);
        // the ecrecover precompile implementation checks that the `r` and `s`
        // inputs are non-zero (in this case, `px` and `ep`), thus we don't need to
        // check if they're zero.
        address R = ecrecover(sp, parity, px, ep);
        require(R != address(0), "ecrecover failed");
        return e == keccak256(abi.encodePacked(R, parity, px, hash));
    }

    /// @notice Should return whether the signature provided is valid for the provided data
    ///  See https://github.com/ethereum/EIPs/issues/1271
    /// @dev This function meets the following conditions as per the EIP:
    ///  MUST return the bytes4 magic value `0x1626ba7e` when function passes.
    ///  MUST NOT modify state (using `STATICCALL` for solc < 0.5, `view` modifier for solc > 0.5)
    ///  MUST allow external calls
    /// @param _hash A 32 byte hash of the signed data.  The actual hash that is hashed however is the
    ///  the following tightly packed arguments: `0x19,0x0,wallet_address,hash`
    /// @param _signature Signature byte array associated with `_data`
    /// @return Magic value `0x1626ba7e` upon success, 0 otherwise.
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4) {
        // We 'hash the hash' for the following reasons:
        // 1. `hash` is not the hash of an Ethereum transaction
        // 2. signature must target this wallet to avoid replaying the signature for another wallet
        // with the same key
        // 3. Gnosis does something similar:
        // https://github.com/gnosis/safe-contracts/blob/102e632d051650b7c4b0a822123f449beaf95aed/contracts/GnosisSafe.sol
        bytes32 operationHash =
            keccak256(abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, _hash));

        return _isValidSignature(operationHash, _signature);
    }

    /// @notice Should return whether the signature provided is valid for the provided data
    ///  See https://github.com/ethereum/EIPs/issues/1271
    /// @dev This function meets the following conditions as per the EIP:
    ///  MUST return the bytes4 magic value `0x1626ba7e` when function passes.
    /// @param _operationHash A 32 byte hash of the signed data.  For internal usage, the _operationHash shoule be hash with EIP191V0 first
    /// @param _signature Signature byte array associated with `_data`
    /// @return Magic value `0x1626ba7e` upon success, 0 otherwise.
    function _isValidSignature(bytes32 _operationHash, bytes calldata _signature) private view returns (bytes4) {
        if (_signature.length == 65 && (_signature[64] & 0x80) > 0) {
            return verifySchnorr(_operationHash, _signature) ? IERC1271.isValidSignature.selector : bytes4(0);
        }

        bytes32[2] memory r;
        bytes32[2] memory s;
        uint8[2] memory v;
        address signer;
        address cosigner;

        // extract 1 or 2 signatures depending on length
        if (_signature.length == 65) {
            (r[0], s[0], v[0]) = _signature.extractSignature(0);
            require(s[0] <= S_MAX, "s of signature[0] is too large");
            signer = ecrecover(_operationHash, v[0], r[0], s[0]);
            cosigner = signer;
        } else if (_signature.length == 130) {
            (r[0], s[0], v[0]) = _signature.extractSignature(0);
            require(s[0] <= S_MAX, "s of signature[0] is too large");
            (r[1], s[1], v[1]) = _signature.extractSignature(65);
            require(s[1] <= S_MAX, "s of signature[1] is too large");
            signer = ecrecover(_operationHash, v[0], r[0], s[0]);
            cosigner = ecrecover(_operationHash, v[1], r[1], s[1]);
        } else {
            return 0;
        }

        // check for valid signature
        if (signer == address(0)) {
            return 0;
        }

        // check for valid signature
        if (cosigner == address(0)) {
            return 0;
        }

        // check to see if this is an authorized key
        if (address(uint160(authorizations[authVersion + uint256(uint160(signer))])) != cosigner) {
            return 0;
        }

        return IERC1271.isValidSignature.selector;
    }

    /// @notice A version of `invoke()` that has no explicit signatures, and uses msg.sender
    ///  as both the signer and cosigner. Will only succeed if `msg.sender` is an authorized
    ///  signer for this wallet, with no cosigner, saving transaction size and gas in that case.
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke0(bytes calldata data) external {
        // The nonce doesn't need to be incremented for transactions that don't include explicit signatures;
        // the built-in nonce of the native ethereum transaction will protect against replay attacks, and we
        // can save the gas that would be spent updating the nonce variable

        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner)
        require(
            address(uint160(authorizations[authVersion + uint256(uint160(msg.sender))])) == msg.sender,
            "invalid authorization"
        );

        internalInvoke(0, data);
    }

    /// @notice A version of `invoke()` that has one explicit signature which is used to derive the authorized
    ///  address. Uses `msg.sender` as the cosigner.
    /// @param v the v value for the signature; see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
    /// @param r the r value for the signature
    /// @param s the s value for the signature
    /// @param inonce the nonce value for the signature
    /// @param authorizedAddress the address of the authorization key; this is used here so that cosigner signatures are interchangeable
    ///  between this function and `invoke2()`
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke1CosignerSends(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 inonce,
        address authorizedAddress,
        bytes calldata data
    ) external {
        // check signature version
        require(v == 27 || v == 28, "invalid signature version");
        require(s <= S_MAX, "s of signature is too large");
        // calculate hash
        bytes32 operationHash = keccak256(
            abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, inonce, authorizedAddress, data)
        );

        // recover signer
        address signer = ecrecover(operationHash, v, r, s);

        // check for valid signature
        require(signer != address(0), "invalid signature");

        // check nonce
        require(inonce > nonce && (inonce < (nonce + 10)), "must use valid nonce for signer");

        // check signer
        require(signer == authorizedAddress, "authorized addresses must be equal");

        // Get cosigner
        address requiredCosigner = address(uint160(authorizations[authVersion + uint256(uint160(signer))]));

        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner) or
        // if the actual cosigner matches the required cosigner.
        require(requiredCosigner == signer || requiredCosigner == msg.sender, "invalid authorization");

        // set nonce
        nonce = inonce;

        // call internal function
        internalInvoke(operationHash, data);
    }

    /// @notice A version of `invoke()` that has one explicit signature which is used to derive the cosigning
    ///  address. Uses `msg.sender` as the authorized address.
    /// @param v the v value for the signature; see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
    /// @param r the r value for the signature
    /// @param s the s value for the signature
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke1SignerSends(uint8 v, bytes32 r, bytes32 s, bytes calldata data) external {
        // check signature version
        // `ecrecover` will in fact return 0 if given invalid
        // so perhaps this check is redundant
        require(v == 27 || v == 28, "invalid signature version");
        require(s <= S_MAX, "s of signature is too large");

        // calculate hash
        bytes32 operationHash = keccak256(
            abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, nonce, msg.sender, data)
        );

        // recover cosigner
        address cosigner = ecrecover(operationHash, v, r, s);

        // check for valid signature
        require(cosigner != address(0), "invalid signature");

        // Get required cosigner
        address requiredCosigner = address(uint160(authorizations[authVersion + uint256(uint160(msg.sender))]));

        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner) or
        // if the actual cosigner matches the required cosigner.
        require(requiredCosigner == cosigner || requiredCosigner == msg.sender, "invalid authorization");

        // increment nonce to prevent replay attacks
        nonce++;

        internalInvoke(operationHash, data);
    }

    /// @notice A version of `invoke()` that use isValidSignature to check the authorization of signers
    /// @param _nonce the nonce value for the signature
    /// @param _data The data containing the transactions to be invoked; see internalInvoke for details.
    /// @param _signature Signature byte array associated with `_nonce, _data`
    function invoke2(uint256 _nonce, bytes calldata _data, bytes calldata _signature) external {
        // calculate hash
        bytes32 operationHash =
            keccak256(abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, _nonce, _data));

        // valid signature
        bytes4 result = _isValidSignature(operationHash, _signature);
        require(result == IERC1271.isValidSignature.selector, "invalid signature");

        // check nonce
        require(_nonce > nonce && (_nonce < (nonce + 10)), "must use valid nonce");

        // set nonce
        nonce = _nonce;

        // call internal function
        internalInvoke(operationHash, _data);
    }

    /// @notice simulate invoke2 result off-chain
    /// @dev this function will revert always
    /// @param _nonce the nonce value for the signature
    /// @param _data The data containing the transactions to be invoked; see internalInvoke for details.
    /// @param _signature Signature byte array associated with `_nonce, _data`
    function simulateInvoke2(uint256 _nonce, bytes calldata _data, bytes calldata _signature) external {
        // calculate hash
        bytes32 operationHash =
            keccak256(abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, _nonce, _data));

        // valid signature
        bytes4 result = _isValidSignature(operationHash, _signature);
        // always pass
        require(result >= 0, "invalid signature");

        // check nonce
        require(_nonce > nonce && (_nonce < type(uint256).max), "must use valid nonce");

        // set nonce
        nonce = _nonce;

        // call internal function
        internalInvoke(operationHash, _data);

        // always revert
        revert ExecutionResult(true);
    }

    /// @dev Internal invoke call,
    /// @param operationHash The hash of the operation
    /// @param data The data to send to the `call()` operation
    ///  The data is prefixed with a global 1 byte revert flag
    ///  If revert is 1, then any revert from a `call()` operation is rethrown.
    ///  Otherwise, the error is recorded in the `result` field of the `InvocationSuccess` event.
    ///  Immediately following the revert byte (no padding), the data format is then is a series
    ///  of 1 or more tightly packed tuples:
    ///  `<target(20),amount(32),datalength(32),data>`
    ///  If `datalength == 0`, the data field must be omitted
    function internalInvoke(bytes32 operationHash, bytes memory data) internal {
        // keep track of the number of operations processed
        uint256 numOps;
        // keep track of the result of each operation as a bit
        uint256 result;

        // We need to store a reference to this string as a variable so we can use it as an argument to
        // the revert call from assembly.
        string memory invalidLengthMessage = "data field too short";
        string memory callFailed = "call failed";

        // At an absolute minimum, the data field must be at least 85 bytes
        // <revert(1), to_address(20), value(32), data_length(32)>
        require(data.length >= 85, invalidLengthMessage);

        // Forward the call onto its actual target. Note that the target address can be `self` here, which is
        // actually the required flow for modifying the configuration of the authorized keys and recovery address.
        //
        // The assembly code below loads data directly from memory, so the enclosing function must be marked `internal`
        assembly {
            // A cursor pointing to the revert flag, starts after the length field of the data object
            let memPtr := add(data, 32)

            // The revert flag is the leftmost byte from memPtr
            let revertFlag := byte(0, mload(memPtr))

            // A pointer to the end of the data object
            let endPtr := add(memPtr, mload(data))

            // Now, memPtr is a cursor pointing to the beginning of the current sub-operation
            memPtr := add(memPtr, 1)

            // Loop through data, parsing out the various sub-operations
            for {} lt(memPtr, endPtr) {} {
                // Load the length of the call data of the current operation
                // 52 = to(20) + value(32)
                let len := mload(add(memPtr, 52))

                // Compute a pointer to the end of the current operation
                // 84 = to(20) + value(32) + size(32)
                let opEnd := add(len, add(memPtr, 84))

                // Bail if the current operation's data overruns the end of the enclosing data buffer
                // NOTE: Comment out this bit of code and uncomment the next section if you want
                // the solidity-coverage tool to work.
                // See https://github.com/sc-forks/solidity-coverage/issues/287
                if gt(opEnd, endPtr) {
                    // The computed end of this operation goes past the end of the data buffer. Not good!
                    revert(add(invalidLengthMessage, 32), mload(invalidLengthMessage))
                }
                // NOTE: Code that is compatible with solidity-coverage
                // switch gt(opEnd, endPtr)
                // case 1 {
                //     revert(add(invalidLengthMessage, 32), mload(invalidLengthMessage))
                // }

                // This line of code packs in a lot of functionality!
                //  - load the target address from memPtr, the address is only 20-bytes but mload always grabs 32-bytes,
                //    so we have to shr by 12 bytes.
                //  - load the value field, stored at memPtr+20
                //  - pass a pointer to the call data, stored at memPtr+84
                //  - use the previously loaded len field as the size of the call data
                //  - make the call (passing all remaining gas to the child call)
                //  - check the result (0 == reverted)
                if eq(0, call(gas(), shr(96, mload(memPtr)), mload(add(memPtr, 20)), add(memPtr, 84), len, 0, 0)) {
                    switch revertFlag
                    case 1 { revert(add(callFailed, 32), mload(callFailed)) }
                    default {
                        // mark this operation as failed
                        // create the appropriate bit, 'or' with previous
                        result := or(result, exp(2, numOps))
                    }
                }

                // increment our counter
                numOps := add(numOps, 1)

                // Update mem pointer to point to the next sub-operation
                memPtr := opEnd
            }
        }

        // emit single event upon success
        emit InvocationSuccess(operationHash, result, numOps);
    }
}