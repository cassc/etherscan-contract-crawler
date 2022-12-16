// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IEventEmitter} from "./interfaces/IEventEmitter.sol";

contract CryptoAvatarsFFA is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BANNED_ROLE = keccak256("BANNED_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;
    IEventEmitter public eventEmitter;
    error Banned();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _eventEmitter) public initializer {
        __ERC721_init("CryptoAvatarsFFA", "CAFFA");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        eventEmitter = IEventEmitter(_eventEmitter);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/";
    }

    function mintAvatar(string memory uri) public {
        if (hasRole(BANNED_ROLE, _msgSender())) {
            revert Banned();
        }
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
        _setTokenURI(tokenId, uri);
        eventEmitter.emitEvent(
            "Mint",
            abi.encode(_msgSender(), uri, tokenId, address(this))
        );
    }

    function updateEventEmitter(
        address _eventEmitter
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        eventEmitter = IEventEmitter(_eventEmitter);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) {
        super.transferFrom(from, to, tokenId);
        IEventEmitter(eventEmitter).emitEvent(
            "Transfer",
            abi.encode(from, to, tokenId, address(this))
        );
    }

    function ban(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(BANNED_ROLE, _address);
    }

    function unban(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(BANNED_ROLE, _address);
    }

    function isBanned(address _address) public view returns (bool) {
        return hasRole(BANNED_ROLE, _address);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId, data);
        IEventEmitter(eventEmitter).emitEvent(
            "Transfer",
            abi.encode(from, to, tokenId, address(this))
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
        IEventEmitter(eventEmitter).emitEvent(
            "Burn",
            abi.encode(_msgSender(), tokenId, address(this))
        );
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // -------------- PAUSING METHODS --------------
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // -------------- OTHER --------------
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}