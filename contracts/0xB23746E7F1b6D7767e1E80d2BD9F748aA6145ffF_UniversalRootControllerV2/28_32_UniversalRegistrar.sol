// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniversalRegistrar.sol";
import "./RegistrarAccess.sol";

contract UniversalRegistrar is ERC721, RegistrarAccess, IUniversalRegistrar, Ownable {
    // A map of expiry times
    mapping(uint256 => uint) expiries;
    ENS public ens;

    // ERC721 Metadata URI
    string private metadataUri;

    // A map of addresses that are authorised to register and renew
    // names for the given top level node.
    mapping(bytes32 => mapping(address => bool)) public controllers;

    uint256 public constant GRACE_PERIOD = 90 days;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ERC721_ID = bytes4(
        keccak256("balanceOf(address)") ^
        keccak256("ownerOf(uint256)") ^
        keccak256("approve(address,uint256)") ^
        keccak256("getApproved(uint256)") ^
        keccak256("setApprovalForAll(address,bool)") ^
        keccak256("isApprovedForAll(address,address)") ^
        keccak256("transferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256,bytes)")
    );
    bytes4 constant private RECLAIM_ID = bytes4(keccak256("reclaim(bytes32,uint256,address)"));

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    constructor(ENS _ens, Root _root) ERC721("Impervious Registry", "IR") RegistrarAccess(_root) {
        ens = _ens;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return metadataUri;
    }

    modifier live(bytes32 node) {
        require(ens.owner(node) == address(this));
        _;
    }

    modifier onlyController(bytes32 node) {
        require(controllers[node][msg.sender]);
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override(IERC721, ERC721) returns (address) {
        require(expiries[tokenId] > block.timestamp);
        return super.ownerOf(tokenId);
    }

    // Change metadata uri
    function setUri(string memory _uri) external onlyOwner {
        metadataUri = _uri;
    }

    // Authorises a controller, who can register and renew domains.
    // can only be called by the node owner.
    function addController(
        bytes32 node,
        address controller
    ) external override onlyNodeOwner(node) onlyRegistryControllers(node, controller) {
        controllers[node][controller] = true;
        emit ControllerAdded(node, controller);
    }

    // Revoke controller permission for an address.
    // can only be called by the node owner.
    function removeController(bytes32 node, address controller) external override onlyNodeOwner(node) {
        controllers[node][controller] = false;
        emit ControllerRemoved(node, controller);
    }

    // Set the resolver for the TLD this registrar manages.
    // can only be called by the node owner.
    function setResolver(bytes32 node, address resolver) external override onlyNodeOwner(node) {
        ens.setResolver(node, resolver);
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view override returns (uint) {
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view override returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }

    /**
     * @dev Register a name.
     * @param node The node hash.
     * @param label The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(bytes32 node, bytes32 label, address owner, uint duration) external override returns (uint) {
        return _register(node, label, owner, duration, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param node The node hash.
     * @param label The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(bytes32 node, bytes32 label, address owner, uint duration) external returns (uint) {
        return _register(node, label, owner, duration, false);
    }

    function _register(bytes32 node, bytes32 label, address owner,
        uint duration, bool updateRegistry) internal live(node) onlyController(node) returns (uint) {
        require(block.timestamp + duration + GRACE_PERIOD > block.timestamp + GRACE_PERIOD); // Prevent future overflow

        uint256 id = _tokenID(node, label);
        require(available(id));

        expiries[id] = block.timestamp + duration;
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
        if (updateRegistry) {
            ens.setSubnodeOwner(node, label, owner);
        }

        emit NameRegistered(node, label, owner, block.timestamp + duration);

        return block.timestamp + duration;
    }

    function renew(bytes32 node, bytes32 label, uint duration) external override live(node) onlyController(node) returns (uint) {
        uint256 id = _tokenID(node, label);
        require(expiries[id] + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period
        require(expiries[id] + duration + GRACE_PERIOD > duration + GRACE_PERIOD); // Prevent future overflow

        expiries[id] += duration;
        emit NameRenewed(node, label, expiries[id]);
        return expiries[id];
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(bytes32 node, bytes32 label, address owner) external override live(node) {
        uint256 id = _tokenID(node, label);
        require(_isApprovedOrOwner(msg.sender, id));
        ens.setSubnodeOwner(node, label, owner);
    }

    function supportsInterface(bytes4 interfaceID) public override(ERC721, IERC165) view returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
        interfaceID == ERC721_ID ||
        interfaceID == RECLAIM_ID;
    }

    function _tokenID(bytes32 node, bytes32 label) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(node, label)));
    }
}