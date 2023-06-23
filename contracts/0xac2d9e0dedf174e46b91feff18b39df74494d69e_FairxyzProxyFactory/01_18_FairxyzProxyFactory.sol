// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import {FairxyzBeaconProxy} from "./FairxyzBeaconProxy.sol";
import {IFairxyzProxyFactory} from "../interfaces/IFairxyzProxyFactory.sol";

/**
 * @title FairxyzProxyFactory
 *
 * @notice Deploys Fair.xyz proxies.
 *
 * @dev Allows proxies for different implementation and beacon contracts to be deployed for Fair.xyz collections.
 * @dev The contract is Ownable and can be upgraded to support different types of proxies and deployment logic in the future.
 */
contract FairxyzProxyFactory is
    UUPSUpgradeable,
    OwnableUpgradeable,
    IFairxyzProxyFactory
{
    using ECDSAUpgradeable for bytes32;

    bytes32 internal constant EIP712_NAME_HASH = keccak256("Fair.xyz");
    bytes32 internal constant EIP712_VERSION_HASH = keccak256("2.0.0");

    bytes32 internal constant EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 internal constant EIP712_DEPLOY_PROXY_TYPE_HASH =
        keccak256(
            "DeployProxy(uint256 collectionId,string implementationName,uint256 nonce,bytes data)"
        );

    address internal fairxyzSigner;

    /// @dev mapping from collection ID to the last used deployment signature nonce
    mapping(uint256 => uint256) internal collectionLastUsedNonce;

    /// @dev mapping from keccak256 hash of implementation contract name to the deployed beacon address
    mapping(bytes32 => address) internal _beacons;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address fairxyzSigner_) external initializer {
        fairxyzSigner = fairxyzSigner_;
        __Ownable_init();
    }

    // * PUBLIC * //

    /**
     * @dev See {IFairxyzProxyFactory-deployProxy}.
     *
     * Emits a {NewProxy} event.
     */
    function deployBeaconProxy(
        uint256 collectionId,
        string calldata implementationName,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata data
    ) external virtual override {
        address beacon = _validateDeploymentParams(
            collectionId,
            implementationName,
            nonce,
            data,
            signature
        );

        FairxyzBeaconProxy proxy = new FairxyzBeaconProxy(beacon, data);

        emit NewProxy(address(proxy), collectionId);
    }

    /**
     * @dev See {IFairxyzProxyFactory-getBeacon}.
     */
    function getBeacon(
        string calldata implementationName
    ) external view virtual override returns (address) {
        return _beacons[keccak256(bytes(implementationName))];
    }

    // * OWNER * //

    /**
     * @dev See {IFairxyzProxyFactory-setBeacon}.
     */
    function setBeacon(
        address beacon,
        string calldata implementationName
    ) external virtual override onlyOwner {
        _beacons[keccak256(bytes(implementationName))] = beacon;
        emit NewBeacon(beacon, implementationName);
    }

    /**
     * @dev See {IFairxyzProxyFactory-setSigner}.
     */
    function setSigner(address signer) external virtual override onlyOwner {
        fairxyzSigner = signer;
    }

    // * INTERNAL * //

    /**
     * @dev Regenerates the expected signature digest for the deploy params.
     */
    function _hashDeployParams(
        uint256 collectionId,
        string calldata implementationName,
        uint256 nonce,
        bytes calldata data
    ) internal view virtual returns (bytes32) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EIP712_DEPLOY_PROXY_TYPE_HASH,
                    collectionId,
                    keccak256(bytes(implementationName)),
                    nonce,
                    keccak256(data)
                )
            )
        );
        return digest;
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                EIP712_NAME_HASH,
                EIP712_VERSION_HASH,
                block.chainid,
                address(this)
            )
        );

        return ECDSAUpgradeable.toTypedDataHash(domainSeparator, structHash);
    }

    function _validateDeploymentParams(
        uint256 collectionId,
        string calldata implementationName,
        uint256 nonce,
        bytes calldata data,
        bytes calldata signature
    ) internal virtual returns (address beacon) {
        beacon = _beacons[keccak256(bytes(implementationName))];

        if (beacon == address(0)) revert InvalidBeacon();

        if (nonce <= collectionLastUsedNonce[collectionId])
            revert InvalidNonce();

        bytes32 deployHash = _hashDeployParams(
            collectionId,
            implementationName,
            nonce,
            data
        );

        if (deployHash.recover(signature) != fairxyzSigner)
            revert InvalidSignature();

        collectionLastUsedNonce[collectionId] = nonce;
    }

    // * UUPS * //

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    // * PRIVATE * //

    uint256[47] private __gap;
}