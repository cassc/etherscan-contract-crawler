// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

//////////////////////////
////    Interfaces    ////
//////////////////////////
import { IAddrResolver } from "ens/resolvers/profiles/IAddrResolver.sol";
import { INameResolver } from "ens/resolvers/profiles/INameResolver.sol";
import { IABIResolver } from "ens/resolvers/profiles/IABIResolver.sol";
import { IPubkeyResolver } from "ens/resolvers/profiles/IPubkeyResolver.sol";
import { ITextResolver } from "ens/resolvers/profiles/ITextResolver.sol";
import { IContentHashResolver } from "ens/resolvers/profiles/IContentHashResolver.sol";
import { IAddressResolver } from "ens/resolvers/profiles/IAddressResolver.sol";

import { IERC3668 } from "./interfaces/IERC3668.sol";
import { IExtendedResolver } from "./interfaces/IExtendedResolver.sol";
import { IWriteDeferral } from "./interfaces/IWriteDeferral.sol";
import { IResolverService } from "./interfaces/IResolverService.sol";

//////////////////////////
////    Libraries     ////
//////////////////////////
import { EnumerableSetUpgradeable } from "openzeppelin/utils/structs/EnumerableSetUpgradeable.sol";
import { StringsUpgradeable } from "openzeppelin/utils/StringsUpgradeable.sol";

import { SignatureVerifierUpgradeable } from "./libraries/SignatureVerifierUpgradeable.sol";
import { ResolverStateHelper } from "./libraries/ResolverStateHelper.sol";
import { TypeToString } from "./libraries/TypeToString.sol";

//////////////////////////
////      Types       ////
//////////////////////////
import { Initializable } from "openzeppelin/proxy/utils/Initializable.sol";
import { ERC165Upgradeable } from "openzeppelin/utils/introspection/ERC165Upgradeable.sol";

import { ManageableUpgradeable } from "./types/ManageableUpgradeable.sol";


//////////////////////////
////      Errors      ////
//////////////////////////
error TimeoutDurationTooShort();
error TimeoutDurationTooLong();

/**
 * @notice Coinbase Offchain ENS Resolver.
 * @dev Adapted from: https://github.com/ensdomains/offchain-resolver/blob/2bc616f19a94370828c35f29f71d5d4cab3a9a4f/packages/contracts/contracts/OffchainResolver.sol
 */
contract CoinbaseResolverUpgradeable is 
    Initializable,
    IERC3668, IWriteDeferral, 
    IExtendedResolver, 

    IAddrResolver, 
    INameResolver,
    IABIResolver,
    ITextResolver,
    IPubkeyResolver,
    IContentHashResolver,
    IAddressResolver,

    ERC165Upgradeable, ManageableUpgradeable {
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event raised when a new signer is added.
    event SignerAdded(address indexed addedSigner);
    /// @notice Event raised when a signer is removed.
    event SignerRemoved(address indexed removedSigner);
    
    /// @notice Event raised when a new gateway URL is set.
    event GatewayUrlSet(string indexed previousUrl, string indexed newUrl);
    
    /// @notice Event raised when a new off-chain database timeout duration is set.
    event OffChainDatabaseTimeoutDurationSet(uint256 previousDuration, uint256 newDuration);

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Universal constant for the ETH coin type.
    uint constant private COIN_TYPE_ETH = 60;

    /// @dev Constant for name used in the domain definition of the off-chain write deferral reversion.
    string constant private WRITE_DEFERRAL_DOMAIN_NAME = "CoinbaseResolver";
    /// @dev Constant specifing the version of the domain definition.
    string constant private WRITE_DEFERRAL_DOMAIN_VERSION = "1";
    /// @dev Constant specifing the chainId that this contract lives on
    uint64 constant private CHAIN_ID = 1;

    /*//////////////////////////////////////////////////////////////
                             SLO CONSTRANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 constant private RESOLVER_STATE_SLO = keccak256("coinbase.resolver.v1.state");

    /*//////////////////////////////////////////////////////////////
                               INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with the initial parameters.
     * @param newOwner Owner address.
     * @param newSignerManager Signer manager address.
     * @param newGatewayManager Gateway manager address.
     * @param newGatewayUrl Gateway URL.
     * @param newOffChainDatabaseUrl OffChainDatabase URL.
     * @param newSigners Signer addresses.
     */
    function initialize(
        address newOwner,
        address newSignerManager,
        address newGatewayManager,
        string memory newGatewayUrl,
        string memory newOffChainDatabaseUrl,
        uint256 newOffChainDatabaseTimeoutDuration,
        address[] memory newSigners
    ) public initializer {
        // initialize dependecies
        ManageableUpgradeable.__Managable_init();

        // Admin / Manager initialization
        _transferOwnership(newOwner);
        _changeSignerManager(newSignerManager);
        _changeGatewayManager(newGatewayManager);

        // State initialization
        _setGatewayUrl(newGatewayUrl);
        _setOffChainDatabaseUrl(newOffChainDatabaseUrl);
        _setOffChainDatabaseTimeoutDuration(newOffChainDatabaseTimeoutDuration);

        _addSigners(newSigners);
    }

    /*//////////////////////////////////////////////////////////////
                            ENSIP-10 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initiate a resolution conforming to the ENSIP-10. Reverts with an OffchainLookup error.
     * @param name DNS-encoded name to resolve.
     * @param data ABI-encoded data for the underlying resolution function (e.g. addr(bytes32), text(bytes32,string)).
     * @return Always reverts with an OffchainLookup error.
     */
    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        override
        returns (bytes memory)
    {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-137 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return Always reverts with an OffchainLookup error.
     */
    function addr(bytes32 node) virtual override public view returns (address payable) {
        addr(node, COIN_TYPE_ETH);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-181 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function setName(bytes32 node, string calldata name) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](2);

        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);
        
        params[1].name = "name";
        params[1].value = name;

        _offChainStorage(params);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return Always reverts with an OffchainLookup error.
     */
    function name(bytes32 node) override view external returns(string memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-205 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](3);
        
        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);

        params[1].name = "content_type";
        params[1].value = contentType.toString();

        params[2].name = "data";
        params[2].value = TypeToString.bytesToString(data);
        
        _offChainStorage(params);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return Always reverts with an OffchainLookup error.
     */
    function ABI(bytes32 node, uint256 contentTypes) external view override returns (uint256, bytes memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-619 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](3);

        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);
        
        params[1].name = "x";
        params[1].value = TypeToString.bytes32ToString(x);
        
        params[2].name = "y";
        params[2].value = TypeToString.bytes32ToString(y);

        _offChainStorage(params);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     * Always reverts with an OffchainLookup error.
     */
    function pubkey(bytes32 node) virtual override external view returns (bytes32 x, bytes32 y) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-634 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](3);
        
        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);
        
        params[1].name = "key";
        params[1].value = key;

        params[2].name = "value";
        params[2].value = value;

        _offChainStorage(params);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return Always reverts with an OffchainLookup error.
     */
    function text(bytes32 node, string calldata key) override external view returns (string memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-1577 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](2);
        
        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);

        params[1].name = "hash";
        params[1].value = TypeToString.bytesToString(hash);

        _offChainStorage(params);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return Always reverts with an OffchainLookup error.
     */
    function contenthash(bytes32 node) external view override returns (bytes memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-2304 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param coinType The constant used to define the coin type of the corresponding address.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, uint coinType, bytes memory a) public {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](3);
        
        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);

        params[1].name = "coin_type";
        params[1].value = StringsUpgradeable.toString(coinType);

        params[2].name = "address";
        params[2].value = TypeToString.bytesToString(a);

        _offChainStorage(params);
    }

    /**
     * Returns the address associated with an ENS node for the corresponding coinType.
     * @param node The ENS node to query.
     * @param coinType The coin type of the corresponding address.
     * @return Always reverts with an OffchainLookup error.
     */
    function addr(bytes32 node, uint coinType) override view public returns(bytes memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                        ENS CCIP RESOLVER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Builds an OffchainLookup error.
     * @param callData The calldata for the corresponding lookup.
     * @return Always reverts with an OffchainLookup error.
     */
    function _offChainLookup(bytes calldata callData) private view returns(bytes memory) {
        string[] memory urls = new string[](1);
        urls[0] = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).gatewayUrl;

        revert OffchainLookup(
            address(this),
            urls,
            callData,
            this.resolveWithProof.selector,
            callData
        );
    }

    /**
     * @notice Callback used by CCIP-read compatible clients to verify and parse the response.
     * @dev Reverts if the signature is invalid.
     * @param response ABI-encoded response data in the form of (bytes result, uint64 expires, bytes signature).
     * @param extraData Original request data.
     * @return ABI-encoded result data for the underlying resolution function.
     */
    function resolveWithProof(bytes calldata response, bytes calldata extraData)
        external
        view
        returns (bytes memory)
    {
        (address signer, bytes memory result) = SignatureVerifierUpgradeable.verify(
            extraData,
            response
        );

        require(
            ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).signers.contains(signer),
            "CoinbaseResolver::resolveWithProof: invalid signature"
        );
        return result;
    }

    /*//////////////////////////////////////////////////////////////
                    ENS WRITE DEFERRAL RESOLVER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Builds an StorageHandledByOffChainDatabase error.
     * @param params The offChainDatabaseParamters used to build the corresponding mutation action.
     */
    function _offChainStorage(IWriteDeferral.parameter[] memory params) private view {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        revert StorageHandledByOffChainDatabase(
            IWriteDeferral.domainData(
                {
                    name: WRITE_DEFERRAL_DOMAIN_NAME,
                    version: WRITE_DEFERRAL_DOMAIN_VERSION,
                    chainId: CHAIN_ID,
                    verifyingContract: address(this)
                }
            ),
            state_.offChainDatabaseUrl,
            IWriteDeferral.messageData(
                {
                    functionSelector: msg.sig,
                    sender: msg.sender,
                    parameters: params,
                    expirationTimestamp: block.timestamp + state_.offChainDatabaseTimeoutDuration
                }
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL ADMINISTRATIVE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the gateway URL.
     * @dev Can only be called by the gateway manager.
     * @param newUrl New gateway URL.
     */
    function setGatewayUrl(string calldata newUrl) external onlyGatewayManager {
        _setGatewayUrl(newUrl);
    }

    /**
     * @notice Set the offChainDatabase URL.
     * @dev Can only be called by the gateway manager.
     * @param newUrl New offChainDatabase URL.
     */
    function setOffChainDatabaseUrl(string calldata newUrl) external onlyGatewayManager {
        _setOffChainDatabaseUrl(newUrl);
    }

    /**
     * @notice Set the offChainDatabase Timeout Duration.
     * @dev Can only be called by the gateway manager.
     * @param newDuration New offChainDatabase timout duration.
     */
    function setOffChainDatabaseTimoutDuration(uint256 newDuration) external onlyGatewayManager {
        _setOffChainDatabaseTimeoutDuration(newDuration);
    }

    /**
     * @notice Add a set of new signers.
     * @dev Can only be called by the signer manager.
     * @param signersToAdd Signer addresses.
     */
    function addSigners(address[] calldata signersToAdd)
        external
        onlySignerManager
    {
        _addSigners(signersToAdd);
    }

    /**
     * @notice Remove a set of existing signers.
     * @dev Can only be called by the signer manager.
     * @param signersToRemove Signer addresses.
     */
    function removeSigners(address[] calldata signersToRemove)
        external
        onlySignerManager
    {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        uint256 length = signersToRemove.length;
        for (uint256 i = 0; i < length; i++) {
            address signer = signersToRemove[i];
            if (state_.signers.remove(signer)) {
                emit SignerRemoved(signer);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the gateway URL.
     * @return Gateway URL.
     */
    function gatewayUrl() external view returns (string memory) {
        return ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).gatewayUrl;
    }

    /**
     * @notice Returns the off-chain database URL.
     * @return OffChainDatabase URL.
     */
    function offChainDatabaseUrl() external view returns (string memory) {
        return ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).offChainDatabaseUrl;
    }

    /**
     * @notice Returns a list of signers.
     * @return List of signers.
     */
    function signers() external view returns (address[] memory) {
        return ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).signers.values();
    }

    /**
     * @notice Returns whether a given account is a signer.
     * @return True if a given account is a signer.
     */
    function isSigner(address account) external view returns (bool) {
        return ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).signers.contains(account);
    }

    /**
     * @notice Generates a hash for signing and verifying the offchain response.
     * @param expires Time at which the signature expires.
     * @param request Request data.
     * @param result Result data.
     * @return Hashed data for signing and verifying.
     */
    function makeSignatureHash(
        uint64 expires,
        bytes calldata request,
        bytes calldata result
    ) external view returns (bytes32) {
        return
            SignatureVerifierUpgradeable.makeSignatureHash(
                address(this),
                expires,
                request,
                result
            );
    }

    /*//////////////////////////////////////////////////////////////
                          PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the new gateway URL and emits a GatewayUrlSet event.
     * @param newUrl New URL to be set.
     */
    function _setGatewayUrl(string memory newUrl) private {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        string memory previousUrl = state_.gatewayUrl;
        state_.gatewayUrl = newUrl;

        emit GatewayUrlSet(previousUrl, newUrl);
    }

    /**
     * @notice Sets the new off-chain database URL and emits an OffChainDatabaseUrlSet event.
     * @param newUrl New URL to be set.
     */
    function _setOffChainDatabaseUrl(string memory newUrl) private {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        string memory previousUrl = state_.offChainDatabaseUrl;
        state_.offChainDatabaseUrl = newUrl;
        
        emit OffChainDatabaseHandlerURLChanged(previousUrl, newUrl);
    }

    /**
     * @notice Sets the new off-chain database timout duration and emits an OffChainDatabaseTimeoutDurationSet event.
     * @param newDuration New timout duration to be set.
     */
    function _setOffChainDatabaseTimeoutDuration(uint256 newDuration) private {
        if (newDuration < 60) revert TimeoutDurationTooShort();
        if (newDuration > 600) revert TimeoutDurationTooLong();

        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        uint256 previousDuration = state_.offChainDatabaseTimeoutDuration;
        state_.offChainDatabaseTimeoutDuration = newDuration;
        
        emit OffChainDatabaseTimeoutDurationSet(previousDuration, newDuration);
    }

    /**
     * @notice Adds new signers and emits a SignersAdded event.
     * @param signersToAdd List of addresses to add as signers.
     */
    function _addSigners(address[] memory signersToAdd) private {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        uint256 length = signersToAdd.length;
        for (uint256 i = 0; i < length; i++) {
            address signer = signersToAdd[i];
            if (state_.signers.add(signer)) {
                emit SignerAdded(signer);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                UTILS 
    //////////////////////////////////////////////////////////////*/

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

    /*//////////////////////////////////////////////////////////////
                               ERC-165 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Support ERC-165 introspection.
     * @param interfaceID Interface ID.
     * @return True if a given interface ID is supported.
     */
    function supportsInterface(bytes4 interfaceID)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceID == type(IExtendedResolver).interfaceId ||
            
            interfaceID == type(IAddrResolver).interfaceId || 
            interfaceID == type(IABIResolver).interfaceId ||
            interfaceID == type(IPubkeyResolver).interfaceId ||
            interfaceID == type(ITextResolver).interfaceId ||
            interfaceID == type(INameResolver).interfaceId ||
            interfaceID == type(IContentHashResolver).interfaceId ||
            interfaceID == type(IAddressResolver).interfaceId ||
            
            super.supportsInterface(interfaceID);
    }
}