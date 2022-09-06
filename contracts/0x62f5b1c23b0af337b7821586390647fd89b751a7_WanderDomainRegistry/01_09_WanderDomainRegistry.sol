// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "ens-contracts/registry/ENS.sol";
import "ens-contracts/ethregistrar/IBaseRegistrar.sol";

contract WanderDomainRegistry is Ownable, Pausable, IERC721Receiver {
    /// Wanderers token
    IERC721 immutable WANDERERS;

    /// ENS Registry
    ENS immutable REGISTRY;

    /// ENS Registrar (token)
    IBaseRegistrar immutable REGISTRAR;

    /// Public resolver
    address immutable RESOLVER;

    /// ".eth" basenode hash
    bytes32 constant ETH_BASENODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    struct NodeLabel {
        bytes32 node;
        bytes32 label;
    }

    // Token IDs => registered node/label
    mapping(uint256 => NodeLabel) public tokenSubnode;

    event DomainDeposited(uint256 tokenId);
    event DomainWithdrawn(uint256 tokenId);

    constructor(
        IERC721 _wanderers,
        ENS _registry,
        IBaseRegistrar _registrar,
        address _resolver
    ) {
        WANDERERS = _wanderers;
        REGISTRY = _registry;
        REGISTRAR = _registrar;
        RESOLVER = _resolver;

        _pause();
    }

    modifier isTokenHolder(uint256 tokenId) {
        require(WANDERERS.ownerOf(tokenId) == msg.sender, "not token holder");
        _;
    }

    modifier tokenNotAssignedToSubnode(uint256 tokenId) {
        require(
            tokenSubnode[tokenId].node != 0 && tokenSubnode[tokenId].label != 0,
            "token already has subnode"
        );
        _;
    }

    /// @dev Pause the contract.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev Unpause the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @dev Claim a subdomain for a token. May only be called by the token holder. If a subdomain for the given token already exists, it will be cleared.
    /// @param tokenId the Wanderers token ID used for the claim
    /// @param node nodehash of the domain
    /// @param label labelhash of the subdomain
    /// @param _owner new owner of subdomain
    function claimSubnode(
        uint256 tokenId,
        bytes32 node,
        bytes32 label,
        address _owner
    ) external isTokenHolder(tokenId) whenNotPaused {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));

        NodeLabel storage currentNodeLabel = tokenSubnode[tokenId];

        // If the token already has a label, clear it
        if (currentNodeLabel.node != 0 || currentNodeLabel.label != 0) {
            _clearSubnode(currentNodeLabel.node, currentNodeLabel.label);
        }

        // Make sure the subnode to be set does not already exist
        require(
            REGISTRY.owner(subnode) == address(0),
            "subnode already in use"
        );

        // Update current node and label
        currentNodeLabel.node = node;
        currentNodeLabel.label = label;

        // Set subnode owner to new owner
        REGISTRY.setSubnodeRecord(node, label, _owner, RESOLVER, 0);
    }

    function clearSubnode(uint256 tokenId)
        external
        isTokenHolder(tokenId)
        whenNotPaused
    {
        NodeLabel storage currentNodeLabel = tokenSubnode[tokenId];
        currentNodeLabel.node = 0;
        currentNodeLabel.label = 0;
        _clearSubnode(currentNodeLabel.node, currentNodeLabel.label);
    }

    function _clearSubnode(bytes32 node, bytes32 label) internal {
        REGISTRY.setSubnodeRecord(node, label, address(0), address(0), 0);
    }

    /// When administrative controls are enabled, allow the owner to withdraw domains
    function withdrawDomain(uint256 tokenId) external onlyOwner whenPaused {
        emit DomainWithdrawn(tokenId);
        REGISTRAR.safeTransferFrom(address(this), owner(), tokenId);
    }

    function foo(uint256 tokenId) external {
        bytes32 namehash = keccak256(
            abi.encodePacked(ETH_BASENODE, bytes32(tokenId))
        );
        REGISTRY.setOwner(namehash, address(this));
    }

    /// IERC721Receiver implementation
    /// @dev when administrative controls are enabled, only the owner can deposit new domains.
    function onERC721Received(
        address, /* operator */
        address from,
        uint256 tokenId,
        bytes calldata /* data */
    ) external whenNotPaused returns (bytes4) {
        // Token is a .eth domain
        require(msg.sender == address(REGISTRAR), "not a domain");

        // When administrative controls are enabled, only the owner can deposit new domains
        if (owner() != address(0)) {
            require(from == owner(), "only owner may add domains");
        }

        // Take control of the domain
        REGISTRAR.reclaim(tokenId, address(this));

        emit DomainDeposited(tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }
}