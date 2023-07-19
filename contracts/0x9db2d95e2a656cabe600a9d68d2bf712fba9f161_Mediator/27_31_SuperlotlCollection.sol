// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SuperlotlCollection is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721URIStorage,
    AccessControlEnumerable,
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    uint256 public constant DIVIDER = 10000;

    uint256 public immutable maxSupply;

    address public royaltyReceiver;
    uint96 public royaltyFraction;

    address public vault;
    address public moonpay;

    // address for manage registrar DefaultOperatorFilterer
    address private _ownerRegistrar;

    Counters.Counter private _tokensCount;
    string private _baseTokenURI;

    mapping(address => EnumerableSet.UintSet) private _usersIDs;

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function owner() public view returns (address) {
        return _ownerRegistrar;
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return (royaltyReceiver, (salePrice * royaltyFraction) / DIVIDER);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, AccessControlEnumerable) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokensCount() external view returns (uint256) {
        return _tokensCount.current();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function usersIds(address user, uint256 index) external view returns (uint256) {
        return _usersIDs[user].at(index);
    }

    function usersIdsContains(address user, uint256 tokenId) external view returns (bool) {
        return _usersIDs[user].contains(tokenId);
    }

    function usersIdsLength(address user) external view returns (uint256) {
        return _usersIDs[user].length();
    }

    function usersIdsList(address user, uint256 offset, uint256 limit) external view returns (uint256[] memory output) {
        uint256 idsLength = _usersIDs[user].length();
        if (offset >= idsLength) return new uint256[](0);
        uint256 to = offset + limit;
        if (idsLength < to) to = idsLength;
        output = new uint256[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _usersIDs[user].at(offset + i);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    event BaseURISetted(string baseTokenURI);
    event MoonpayUpdated(address indexed moonpay);
    event OwnerRegistrarUpdated(address indexed owner);
    event RoyaltyReceiverUpdated(address indexed receiver);
    event VaultUpdated(address indexed vault);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint256 maxSupply_,
        address royaltyReceiver_,
        uint96 royaltyFraction_,
        address moonpay_,
        address ownerRegistrar_
    ) ERC721(name_, symbol_) {
        require(maxSupply_ > 0, "Collection: Max supply is not positive");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
        royaltyFraction = royaltyFraction_;
        _updateRoyaltyReceiver(royaltyReceiver_);
        _updateMoonpay(moonpay_);
        _updateOwnerRegistrar(ownerRegistrar_);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function burnBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            super.burn(tokenIds[i]);
        }
    }

    function mint(address to) public payable onlyRole(MINTER_ROLE) nonReentrant {
        _mint(to);
    }

    function mintBatch(address to, uint256 amount) public payable onlyRole(MINTER_ROLE) nonReentrant {
        require(amount > 0, "Collection: amount is not positive");
        for (uint256 i = 0; i < amount; i++) {
            _mint(to);
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function setBaseURI(string memory baseTokenURI_) public onlyRole(URI_SETTER_ROLE) {
        _baseTokenURI = baseTokenURI_;
        emit BaseURISetted(baseTokenURI_);
    }

    function updateRoyaltyReceiver(address receiver) public onlyRole(ADMIN_ROLE) {
        _updateRoyaltyReceiver(receiver);
    }

    function updateMoonpay(address moonpay_) public onlyRole(ADMIN_ROLE) {
        _updateMoonpay(moonpay_);
    }

    function updateOwnerRegistrar(address owner_) public onlyRole(ADMIN_ROLE) {
        _updateOwnerRegistrar(owner_);
    }

    function updateVault(address vault_) public onlyRole(ADMIN_ROLE) {
        require(vault_ != address(0), "Collection: Vault is zero address");
        vault = vault_;
        emit VaultUpdated(vault_);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256) internal override {
        _usersIDs[from].remove(tokenId);
        _usersIDs[to].add(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) onlyAllowedOperator(from) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _mint(address to) private {
        uint256 balance = address(this).balance;
        if (balance > 0) payable(vault).transfer(balance);
        if (msg.sender == moonpay) to = msg.sender;
        _tokensCount.increment();
        uint256 tokenId = _tokensCount.current();
        require(tokenId <= maxSupply, "Collection: token amount gt max supply");
        _safeMint(to, tokenId);
    }

    function _updateRoyaltyReceiver(address receiver) private {
        require(receiver != address(0), "Collection: receiver is zero address");
        royaltyReceiver = receiver;
        emit RoyaltyReceiverUpdated(receiver);
    }

    function _updateMoonpay(address moonpay_) private {
        moonpay = moonpay_;
        emit MoonpayUpdated(moonpay_);
    }

    function _updateOwnerRegistrar(address owner_) private {
        require(owner_ != address(0), "Collection: owner registrar is zero address");
        _ownerRegistrar = owner_;
        emit OwnerRegistrarUpdated(owner_);
    }
}