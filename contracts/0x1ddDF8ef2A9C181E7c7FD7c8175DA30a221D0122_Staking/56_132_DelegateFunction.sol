// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IDelegateFunction.sol";
import "../interfaces/events/EventSender.sol";
import "../interfaces/events/DelegationDisabled.sol";
import "../interfaces/events/DelegationEnabled.sol";
import "../interfaces/IERC1271.sol";

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// solhint-disable var-name-mixedcase
contract DelegateFunction is
    IDelegateFunction,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EventSender
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using SafeMathUpgradeable for uint256;
    using ECDSA for bytes32;

    bytes4 public constant EIP1271_MAGICVALUE = 0x1626ba7e;

    string public constant EIP191_HEADER = "\x19\x01";

    bytes32 public immutable EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public immutable DELEGATE_PAYLOAD_TYPEHASH =
        keccak256(
            "DelegatePayload(uint256 nonce,DelegateMap[] sets)DelegateMap(bytes32 functionId,address otherParty,bool mustRelinquish)"
        );

    bytes32 public immutable DELEGATE_MAP_TYPEHASH =
        keccak256("DelegateMap(bytes32 functionId,address otherParty,bool mustRelinquish)");

    bytes32 public immutable FUNCTIONS_LIST_PAYLOAD_TYPEHASH =
        keccak256("FunctionsListPayload(uint256 nonce,bytes32[] sets)");

    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private CACHED_EIP712_DOMAIN_SEPARATOR;
    uint256 private CACHED_CHAIN_ID;

    bytes32 public constant DOMAIN_NAME = keccak256("Tokemak Delegate Function");
    bytes32 public constant DOMAIN_VERSION = keccak256("1");

    /// @dev Stores the users next valid vote nonce
    mapping(address => uint256) public override contractWalletNonces;

    EnumerableSetUpgradeable.Bytes32Set private allowedFunctions;

    //from => functionId => (otherParty, mustRelinquish, functionId)
    mapping(address => mapping(bytes32 => Destination)) private delegations;

    // account => functionId => number of delegations
    mapping(address => mapping(bytes32 => uint256)) public numDelegationsTo;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        CACHED_CHAIN_ID = _getChainID();
        CACHED_EIP712_DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    function getDelegations(address from)
        external
        view
        override
        returns (DelegateMapView[] memory maps)
    {
        uint256 numOfFunctions = allowedFunctions.length();
        maps = new DelegateMapView[](numOfFunctions);
        for (uint256 ix = 0; ix < numOfFunctions; ix++) {
            bytes32 functionId = allowedFunctions.at(ix);
            Destination memory existingDestination = delegations[from][functionId];
            if (existingDestination.otherParty != address(0)) {
                maps[ix] = DelegateMapView({
                    functionId: functionId,
                    otherParty: existingDestination.otherParty,
                    mustRelinquish: existingDestination.mustRelinquish,
                    pending: existingDestination.pending
                });
            }
        }
    }

    function getDelegation(address from, bytes32 functionId)
        external
        view
        override
        returns (DelegateMapView memory map)
    {
        Destination memory existingDestination = delegations[from][functionId];
        map = DelegateMapView({
            functionId: functionId,
            otherParty: existingDestination.otherParty,
            mustRelinquish: existingDestination.mustRelinquish,
            pending: existingDestination.pending
        });
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function delegate(DelegateMap[] memory sets) external override whenNotPaused {
        _delegate(msg.sender, sets);
    }

    function delegateWithEIP1271(
        address contractAddress,
        DelegatePayload memory delegatePayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 delegatePayloadHash = _hashDelegate(delegatePayload, signatureType);
        _verifyNonce(contractAddress, delegatePayload.nonce);

        _verifyIERC1271Signature(contractAddress, delegatePayloadHash, signature);

        _delegate(contractAddress, delegatePayload.sets);
    }

    function acceptDelegation(DelegatedTo[] calldata incoming) external override whenNotPaused {
        _acceptDelegation(msg.sender, incoming);
    }

    function acceptDelegationOnBehalfOf(
        address[] calldata froms,
        DelegatedTo[][] calldata incomings
    ) external onlyOwner whenNotPaused {
        uint256 length = froms.length;
        require(length > 0, "NO_RECORDS");
        require(length == incomings.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < length; i++) {
            _acceptDelegation(froms[i], incomings[i]);
        }
    }

    function removeDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 functionsListPayloadHash = _hashFunctionsList(functionsListPayload, signatureType);

        _verifyNonce(contractAddress, functionsListPayload.nonce);

        _verifyIERC1271Signature(contractAddress, functionsListPayloadHash, signature);

        _removeDelegations(contractAddress, functionsListPayload.sets);
    }

    function removeDelegation(bytes32[] calldata functionIds) external override whenNotPaused {
        _removeDelegations(msg.sender, functionIds);
    }

    function rejectDelegation(DelegatedTo[] calldata rejections) external override whenNotPaused {
        uint256 length = rejections.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegatedTo memory pending = rejections[ix];
            _rejectDelegation(msg.sender, pending);
        }
    }

    function relinquishDelegation(DelegatedTo[] calldata relinquish)
        external
        override
        whenNotPaused
    {
        uint256 length = relinquish.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            _relinquishDelegation(msg.sender, relinquish[ix]);
        }
    }

    function cancelPendingDelegation(bytes32[] calldata functionIds)
        external
        override
        whenNotPaused
    {
        _cancelPendingDelegations(msg.sender, functionIds);
    }

    function cancelPendingDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 functionsListPayloadHash = _hashFunctionsList(functionsListPayload, signatureType);

        _verifyNonce(contractAddress, functionsListPayload.nonce);

        _verifyIERC1271Signature(contractAddress, functionsListPayloadHash, signature);

        _cancelPendingDelegations(contractAddress, functionsListPayload.sets);
    }

    function setAllowedFunctions(AllowedFunctionSet[] calldata functions)
        external
        override
        onlyOwner
    {
        uint256 length = functions.length;
        require(functions.length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            require(allowedFunctions.add(functions[ix].id), "ADD_FAIL");
        }

        emit AllowedFunctionsSet(functions);
    }

    function canControlEventSend() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _acceptDelegation(address delegatee, DelegatedTo[] calldata incoming) private {
        uint256 length = incoming.length;
        require(length > 0, "NO_DATA");
        require(delegatee != address(0), "INVALID_ADDRESS");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegatedTo calldata deleg = incoming[ix];
            Destination storage destination = delegations[deleg.originalParty][deleg.functionId];
            require(destination.otherParty == delegatee, "NOT_ASSIGNED");
            require(destination.pending, "ALREADY_ACCEPTED");
            require(
                delegations[delegatee][deleg.functionId].otherParty == address(0),
                "ALREADY_DELEGATOR"
            );

            destination.pending = false;
            numDelegationsTo[destination.otherParty][deleg.functionId] = numDelegationsTo[
                destination.otherParty
            ][deleg.functionId].add(1);

            bytes memory data = abi.encode(
                DelegationEnabled({
                    eventSig: "DelegationEnabled",
                    from: deleg.originalParty,
                    to: delegatee,
                    functionId: deleg.functionId
                })
            );

            sendEvent(data);

            emit DelegationAccepted(
                deleg.originalParty,
                delegatee,
                deleg.functionId,
                destination.mustRelinquish
            );
        }
    }

    function _delegate(address from, DelegateMap[] memory sets) internal {
        uint256 length = sets.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegateMap memory set = sets[ix];

            require(allowedFunctions.contains(set.functionId), "INVALID_FUNCTION");
            require(set.otherParty != address(0), "INVALID_DESTINATION");
            require(set.otherParty != from, "NO_SELF");
            require(numDelegationsTo[from][set.functionId] == 0, "ALREADY_DELEGATEE");

            //Remove any existing delegation
            Destination memory existingDestination = delegations[from][set.functionId];
            if (existingDestination.otherParty != address(0)) {
                _removeDelegation(from, set.functionId, existingDestination);
            }

            delegations[from][set.functionId] = Destination({
                otherParty: set.otherParty,
                mustRelinquish: set.mustRelinquish,
                pending: true
            });

            emit PendingDelegationAdded(from, set.otherParty, set.functionId, set.mustRelinquish);
        }
    }

    function _rejectDelegation(address to, DelegatedTo memory pending) private {
        Destination memory existingDestination = delegations[pending.originalParty][
            pending.functionId
        ];
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
        require(existingDestination.pending, "ALREADY_ACCEPTED");

        delete delegations[pending.originalParty][pending.functionId];

        emit DelegationRejected(
            pending.originalParty,
            to,
            pending.functionId,
            existingDestination.mustRelinquish
        );
    }

    function _removeDelegations(address from, bytes32[] calldata functionIds) private {
        uint256 length = functionIds.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            Destination memory existingDestination = delegations[from][functionIds[ix]];
            _removeDelegation(from, functionIds[ix], existingDestination);
        }
    }

    function _removeDelegation(
        address from,
        bytes32 functionId,
        Destination memory existingDestination
    ) private {
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(!existingDestination.mustRelinquish, "EXISTING_MUST_RELINQUISH");

        delete delegations[from][functionId];

        if (existingDestination.pending) {
            emit PendingDelegationRemoved(
                from,
                existingDestination.otherParty,
                functionId,
                existingDestination.mustRelinquish
            );
        } else {
            numDelegationsTo[existingDestination.otherParty][functionId] = numDelegationsTo[
                existingDestination.otherParty
            ][functionId].sub(1);
            _sendDisabledEvent(from, existingDestination.otherParty, functionId);

            emit DelegationRemoved(
                from,
                existingDestination.otherParty,
                functionId,
                existingDestination.mustRelinquish
            );
        }
    }

    function _relinquishDelegation(address to, DelegatedTo calldata relinquish) private {
        Destination memory existingDestination = delegations[relinquish.originalParty][
            relinquish.functionId
        ];
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
        require(!existingDestination.pending, "NOT_YET_ACCEPTED");

        numDelegationsTo[existingDestination.otherParty][relinquish.functionId] = numDelegationsTo[
            existingDestination.otherParty
        ][relinquish.functionId].sub(1);
        delete delegations[relinquish.originalParty][relinquish.functionId];

        _sendDisabledEvent(relinquish.originalParty, to, relinquish.functionId);

        emit DelegationRelinquished(
            relinquish.originalParty,
            to,
            relinquish.functionId,
            existingDestination.mustRelinquish
        );
    }

    function _sendDisabledEvent(
        address from,
        address to,
        bytes32 functionId
    ) private {
        bytes memory data = abi.encode(
            DelegationDisabled({
                eventSig: "DelegationDisabled",
                from: from,
                to: to,
                functionId: functionId
            })
        );

        sendEvent(data);
    }

    function _cancelPendingDelegations(address from, bytes32[] calldata functionIds) private {
        uint256 length = functionIds.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            _cancelPendingDelegation(from, functionIds[ix]);
        }
    }

    function _cancelPendingDelegation(address from, bytes32 functionId) private {
        require(allowedFunctions.contains(functionId), "INVALID_FUNCTION");

        Destination memory existingDestination = delegations[from][functionId];
        require(existingDestination.otherParty != address(0), "NO_PENDING");
        require(existingDestination.pending, "NOT_PENDING");

        delete delegations[from][functionId];

        emit PendingDelegationRemoved(
            from,
            existingDestination.otherParty,
            functionId,
            existingDestination.mustRelinquish
        );
    }

    function _hashDelegate(DelegatePayload memory delegatePayload, SignatureType signatureType)
        private
        view
        returns (bytes32)
    {
        bytes32 x = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                _domainSeparatorV4(),
                _hashDelegatePayload(delegatePayload)
            )
        );

        if (signatureType == SignatureType.ETHSIGN) {
            x = x.toEthSignedMessageHash();
        }

        return x;
    }

    function _hashDelegatePayload(DelegatePayload memory delegatePayload)
        private
        view
        returns (bytes32)
    {
        bytes32[] memory encodedSets = new bytes32[](delegatePayload.sets.length);
        for (uint256 ix = 0; ix < delegatePayload.sets.length; ix++) {
            encodedSets[ix] = _hashDelegateMap(delegatePayload.sets[ix]);
        }

        return
            keccak256(
                abi.encode(
                    DELEGATE_PAYLOAD_TYPEHASH,
                    delegatePayload.nonce,
                    keccak256(abi.encodePacked(encodedSets))
                )
            );
    }

    function _hashDelegateMap(DelegateMap memory delegateMap) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DELEGATE_MAP_TYPEHASH,
                    delegateMap.functionId,
                    delegateMap.otherParty,
                    delegateMap.mustRelinquish
                )
            );
    }

    function _hashFunctionsList(
        FunctionsListPayload calldata functionsListPayload,
        SignatureType signatureType
    ) private view returns (bytes32) {
        bytes32 x = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        FUNCTIONS_LIST_PAYLOAD_TYPEHASH,
                        functionsListPayload.nonce,
                        keccak256(abi.encodePacked(functionsListPayload.sets))
                    )
                )
            )
        );

        if (signatureType == SignatureType.ETHSIGN) {
            x = x.toEthSignedMessageHash();
        }

        return x;
    }

    function _verifyIERC1271Signature(
        address contractAddress,
        bytes32 payloadHash,
        bytes memory signature
    ) private view {
        try IERC1271(contractAddress).isValidSignature(payloadHash, signature) returns (
            bytes4 result
        ) {
            require(result == EIP1271_MAGICVALUE, "INVALID_SIGNATURE");
        } catch {
            revert("INVALID_SIGNATURE_VALIDATION");
        }
    }

    function _verifyNonce(address account, uint256 nonce) private {
        require(contractWalletNonces[account] == nonce, "INVALID_NONCE");
        // Ensure the message cannot be replayed
        contractWalletNonces[account] = nonce.add(1);
    }

    function _getChainID() private pure returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (_getChainID() == CACHED_CHAIN_ID) {
            return CACHED_EIP712_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    DOMAIN_NAME,
                    DOMAIN_VERSION,
                    _getChainID(),
                    address(this)
                )
            );
    }
}