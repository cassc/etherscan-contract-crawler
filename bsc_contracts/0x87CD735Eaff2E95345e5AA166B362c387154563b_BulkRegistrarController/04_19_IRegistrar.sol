// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IControllable.sol";
import "./IRegistrar.sol";
import "./IRegistry.sol";

interface IRegistrar is IControllable {
    event NameRegistered(
        uint256 indexed tokenId,
        uint256 indexed labelId,
        address indexed owner,
        uint256 expires
    );
    event NameRenewed(
        uint256 indexed tokenId,
        uint256 indexed labelId,
        uint256 expires
    );

    /**
     * @dev Returns the registrar tld name.
     */
    function tld() external view returns (string memory);

    // The namehash of the TLD this registrar owns (eg, namehash('registrar addr'+'eth'))
    function baseNode() external view returns (bytes32);

    function gracePeriod() external pure returns (uint256);

    /**
     * @dev Returns the domain name of the `tokenId`.
     */
    function nameOf(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns the `tokenId` of the `labelId`.
     */
    function tokenOf(uint256 labelId) external view returns (uint256);

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 labelId) external view returns (uint256);

    // Returns true if the specified name is available for registration.
    function available(uint256 labelId) external view returns (bool);

    // Returns the registrar issuer address.
    function issuer() external view returns (address);

    // Returns the recipient of name register or renew fees.
    function feeRecipient() external view returns (address payable);

    // Returns the price oracle address.
    function priceOracle() external view returns (address);

    function nextTokenId() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    // Register a name.
    function register(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver
    ) external returns (uint256 tokenId, uint256 expires);

    // Extend a name.
    function renew(uint256 labelId, uint256 duration)
        external
        returns (uint256 tokenId, uint256 expires);

    /**
     * @dev Reclaim ownership of a name, if you own it in the registrar.
     */
    function reclaim(uint256 labelId, address owner) external;
}