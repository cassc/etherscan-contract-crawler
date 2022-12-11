// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

/**
 * @title ERC721Base
 * This contracts introduces upgradeability, pausability, reentrancy guard and access control to all smart
 * contracts that inherit from it
 */

abstract contract ERC721Base is
ERC721EnumerableUpgradeable,
AccessControlUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable,
UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    bytes32 public constant PAUSABILITY_ROLE = keccak256('PAUSABILITY_ROLE');
    bytes32 public constant MANAGE_UPGRADES_ROLE = keccak256('MANAGE_UPGRADES_ROLE');
    bytes32 public constant MANAGE_COLLECTION_ROLE = keccak256('MANAGE_COLLECTION_ROLE');

    uint256 public pricePerToken;
    uint256 public teamReserve;
    uint256 public maxTotalSupply;
    uint256 public mintedTokens;

    string public baseURI;
    string public baseExtension;
    string public contractURI_;
    string public notRevealedURI;
    bool public metadataFrozen;
    address public owner;

    // Custom errors
    error InsufficientPayment();
    error InvalidParameter();
    error MaxMintsReached();
    error MetadataFrozen();
    error UnauthorizedFunctionCall();

    // Custom Modifiers
    modifier ensurePayment (uint256 _mintAmount) {
        if (msg.value < (_mintAmount * pricePerToken))
            revert InsufficientPayment();
        _;
    }
    modifier onlyRoleCustom (bytes32 _roleName) {
        if (!hasRole(_roleName, _msgSender())) revert UnauthorizedFunctionCall();
        _;
    }

    // EVENTS
    event TokenMinted(
        uint256 tokenId,
        address to
    );

    function __ERC721Base_init(
        string memory _name,
        string memory _symbol,
        string memory _initialBaseURI,
        string memory _initialContractURI,
        uint256 _pricePerToken,
        uint256 _teamReserve,
        uint256 _maxTotalSupply
    ) internal initializer {
        __ReentrancyGuard_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();

        owner = address(0xE0A67B78555827b3758531c1Ff938199a3512F15);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);

        maxTotalSupply = _maxTotalSupply;
        baseURI = _initialBaseURI;
        contractURI_ = _initialContractURI;
        pricePerToken = _pricePerToken;
        teamReserve = _teamReserve;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function burn(uint256 tokenId) external {
        if (!_exists(tokenId)) revert InvalidParameter();
        if (ownerOf(tokenId) != _msgSender() && getApproved(tokenId) != _msgSender()) revert UnauthorizedFunctionCall();
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override (AccessControlUpgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        if (!_exists(_tokenId)) revert InvalidParameter();
        return string(abi.encodePacked(baseURI, "/", _tokenId.toString(), baseExtension));
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    function _batchMint(address _to, uint256 _mintAmount) internal nonReentrant whenNotPaused {
        if (mintedTokens + _mintAmount > maxTotalSupply) {
            revert MaxMintsReached();
        }
        for (uint8 i = 0; i < _mintAmount; i++) {
            _safeMint(_to, mintedTokens++);
        }
    }

    function mintReserve(address _to, uint256 _reserveAmount) external onlyRoleCustom(MANAGE_COLLECTION_ROLE) {
        if (_reserveAmount > teamReserve) {
            revert MaxMintsReached();
        }
        teamReserve = teamReserve - _reserveAmount;
        _batchMint(_to, _reserveAmount);
    }

    function freezeMetadata() external onlyRoleCustom(MANAGE_COLLECTION_ROLE) {
        metadataFrozen = true;
    }

    function setPricePerToken(uint256 _newPricePerToken) external onlyRoleCustom(MANAGE_COLLECTION_ROLE) {
        pricePerToken = _newPricePerToken;
    }

    function setOwner(address _newOwner) external onlyRoleCustom(MANAGE_COLLECTION_ROLE) {
        owner = _newOwner;
    }

    function setURIs(
        string memory _newBaseURI,
        string memory _newBaseExtension,
        string memory _newContractURI
    )
    external
    virtual
    onlyRoleCustom(MANAGE_COLLECTION_ROLE)
    {
        if (metadataFrozen) {
            revert MetadataFrozen();
        }
        baseURI = _newBaseURI;
        baseExtension = _newBaseExtension;
        contractURI_ = _newContractURI;
    }

    function pause() external whenNotPaused onlyRoleCustom(PAUSABILITY_ROLE) {
       _pause();

    }

    function unpause() external whenPaused  onlyRoleCustom(PAUSABILITY_ROLE) {
        PausableUpgradeable._unpause();
    }

    function _authorizeUpgrade(address) internal view override onlyRoleCustom(MANAGE_UPGRADES_ROLE) {
        // This function intentionally does not contain any code. The role check is what's important.
    }

    function withdrawFunds(address payable receiver) external onlyRoleCustom(MANAGE_COLLECTION_ROLE) {
        receiver.transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, 1);
    }

    receive() payable external {
    }
}