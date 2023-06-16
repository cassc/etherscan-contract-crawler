// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interface/ID4AERC721Factory.sol";

contract D4AERC721 is
    Initializable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    ERC721RoyaltyUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal _tokenIds;

    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant ROYALTY_OWNER = keccak256("ROYALTY");

    string internal project_uri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setContractUri(string memory _uri) public onlyOwner {
        project_uri = _uri;
    }

    function contractURI() public view returns (string memory) {
        return project_uri;
    }

    function initialize(string memory name, string memory symbol) public virtual initializer {
        __D4AERC721_init(name, symbol);
    }

    function __D4AERC721_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __ERC721Royalty_init();

        __AccessControl_init();
        __Ownable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _tokenIds.reset();
    }

    function mintItem(address player, string memory uri) public onlyRole(MINTER) returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, uri);
        return newItemId;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) public onlyRole(ROYALTY_OWNER) {
        _setDefaultRoyalty(_receiver, _royaltyFeeInBips);
    }

    function _burn(uint256 _tokenId) internal override(ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable) {
        super._burn(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function changeAdmin(address new_admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.sender != new_admin, "new admin cannot be same as old one");
        _grantRole(DEFAULT_ADMIN_ROLE, new_admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

contract D4AERC721Factory is ID4AERC721Factory {
    using Clones for address;

    D4AERC721 impl;

    event NewD4AERC721(address addr);

    constructor() {
        impl = new D4AERC721();
    }

    function createD4AERC721(string memory _name, string memory _symbol) public returns (address) {
        address t = address(impl).clone();
        D4AERC721(t).initialize(_name, _symbol);
        D4AERC721(t).changeAdmin(msg.sender);
        D4AERC721(t).transferOwnership(msg.sender);
        emit NewD4AERC721(t);
        return t;
    }
}