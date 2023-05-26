pragma solidity ^0.8.4;

import "../registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseRegistrar is Ownable, IERC721 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameRegistered(uint256 indexed id, address indexed owner);

    // The ENS registry
    ENS public ens;

    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;

    // A map of addresses that are authorised to register names.
    mapping(address=>bool) public controllers;

    // Authorises a controller, who can register domains.
    function addController(address controller) virtual external;

    // Revoke controller permission for an address.
    function removeController(address controller) virtual external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) virtual external;

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) virtual public view returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner) virtual external;

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) virtual external;
}