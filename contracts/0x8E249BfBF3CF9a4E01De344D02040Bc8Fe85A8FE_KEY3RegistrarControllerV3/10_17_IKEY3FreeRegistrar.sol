// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IKEY3.sol";

interface IKEY3FreeRegistrar is IERC721 {
    event NameRegistered(uint256 indexed id, address indexed owner);

    function baseNode() external view returns (bytes32);

    function key3() external view returns (IKEY3);

    // Authorizes a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) external view returns (bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner) external;

    /**
     * @dev Reclaim ownership of a name in KEY3, if you own it in the registrar.`
     */
    function reclaim(uint256 id, address owner) external;
}