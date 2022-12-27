// SPDX-License-Identifier: CC0-1.0

/// @title ENS Avatar Mirror

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IENSAvatarMirrorNameLabeler} from "./interfaces/IENSAvatarMirrorNameLabeler.sol";
import {IENSAvatarMirrorNodeResolver} from "./interfaces/IENSAvatarMirrorNodeResolver.sol";
import {IENSAvatarMirrorDescriptor} from "./interfaces/IENSAvatarMirrorDescriptor.sol";
import {IENSAvatarMirrorDataReader} from "./interfaces/IENSAvatarMirrorDataReader.sol";

error NotDomainOwner();
error SameSenderAndReceiver();
error AccountBoundToken();
error HasNoReverseDomain();

contract ENSAvatarMirror is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct TokenDetails {
        address minter;
        bytes32 node;
        string domain;
    }

    mapping(uint256 => TokenDetails) internal _tokenDetails;

    address public ens;

    IENSAvatarMirrorDescriptor public descriptor;
    IENSAvatarMirrorNameLabeler public nameLabeler;
    IENSAvatarMirrorDataReader public dataReader;
    IENSAvatarMirrorNodeResolver public nodeResolver;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setDescriptor(address _descriptor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        descriptor = IENSAvatarMirrorDescriptor(_descriptor);
    }

    function setNameLabeler(address _nameLabeler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nameLabeler = IENSAvatarMirrorNameLabeler(_nameLabeler);
    }

    function setDataReader(address _dataReader) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dataReader = IENSAvatarMirrorDataReader(_dataReader);
    }

    function setNodeResolver(address _nodeResolver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nodeResolver = IENSAvatarMirrorNodeResolver(_nodeResolver);
    }

    function transferOwnership(address newOwner) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _transferOwnership(newOwner);
    }

    function mint(address to) external returns (uint256) {
        string memory domain = nodeResolver.reverseDomain(msg.sender);
        if (bytes(domain).length == 0) {
            revert HasNoReverseDomain();
        }
        bytes32 node = nameLabeler.namehash(domain);
        return mintTo(node, domain, to);
    }

    function mint(string memory domain, address to) external returns (uint256) {
        bytes32 node = nameLabeler.namehash(domain);
        return mintTo(node, domain, to);
    }

    function mintTo(bytes32 node, string memory domain, address to) internal returns (uint256) {
        if (nodeResolver.getNodeOwner(node) != msg.sender) {
            revert NotDomainOwner();
        }

        if (to == msg.sender) {
            revert SameSenderAndReceiver();
        }

        uint256 tokenId = uint256(keccak256(abi.encodePacked(node, to)));
        _safeMint(to, tokenId);
        _tokenDetails[tokenId] = TokenDetails(msg.sender, node, domain);

        return tokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 tokenId)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, firstTokenId, tokenId);

        if (from == address(0) || to == address(0)) {
            /* allow during minting or burning */
            return;
        }

        if (from != to) {
            revert AccountBoundToken();
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return descriptor.tokenURI(_tokenDetails[tokenId].domain, _tokenDetails[tokenId].node);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}