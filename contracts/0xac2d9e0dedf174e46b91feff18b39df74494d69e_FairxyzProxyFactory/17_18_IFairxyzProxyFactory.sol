// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFairxyzProxyFactory {
    error InvalidBeacon();
    error InvalidNonce();
    error InvalidSignature();

    /// @dev Emitted when a new beacon is added to the factory that proxies can be deployed for.
    event NewBeacon(address beacon, string implementationName);

    /// @dev Emitted when a new proxy is deployed for a collection.
    event NewProxy(address proxy, uint256 collectionId);

    /**
     * @dev Deploys a new proxy of the given contract type for the specified collection ID.
     *
     * @param collectionId the ID of the Fair.xyz collection
     * @param implementationName the name of the implementation contract used to determine the beacon used for the proxy
     * @param nonce nonce used to prevent redeployment with a duplicate signature
     * @param signature signed digest to restrict calls to only those with a valid platform signature
     * @param data the encoded function data used to call the newly deployed proxy
     */
    function deployBeaconProxy(
        uint256 collectionId,
        string calldata implementationName,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata data
    ) external;

    /**
     * @dev Returns the beacon address for the given contract type.
     *
     * @param implementationName name of the implementation contract that a proxy is deployable for
     */
    function getBeacon(
        string calldata implementationName
    ) external view returns (address);

    /**
     * @dev Sets a new beacon address for deployable proxies.
     *
     * @param beacon address of the beacon for the deployable proxies of this type
     * @param implementationName name of the implementation contract that a proxy is deployable for
     */
    function setBeacon(
        address beacon,
        string calldata implementationName
    ) external;

    /**
     * @dev Sets a new signer address for validating signatures.
     *
     * @param signer address of the signer
     */
    function setSigner(address signer) external;
}