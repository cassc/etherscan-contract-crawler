// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error Claimed();
error notOwner();
error blockedAddress();


contract RealAgency is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    ERC2981,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    string public constant NAME = "REAL AGENCY";
    string public constant SYMBOL = "AGENTS";
    string private _baseTokenURI;
    address private _v1Contract;
    address private _v1VaultAddress;

    mapping(uint256 => bool) private claimed;

    // restrictions toggle
    bool private _marketplaceProtection;
    bool private _transferProtection;
    bool public _upgradeEnabled;


    mapping(address => bool) private _approvedMarketplaces;
    mapping(address => bool) private _blockedTransfers;

    event Mint(address indexed _to, uint256 _tokenId);
    constructor(string memory _uri, address _contract, address _v1recipient) ERC721(NAME, SYMBOL) {
        _setDefaultRoyalty(address(0xa4E40b1d48312Bfb09c8d0c9Cd0fb925c05274E8), 1000);
        _baseTokenURI = _uri;
        _v1Contract = _contract;
        _v1VaultAddress = _v1recipient;

        // satisfy the OS dictatorship
        _marketplaceProtection = true;
        _transferProtection = true;

        // toggle ability to upgrade keys
        _upgradeEnabled = false;
    }

    function pause() public payable onlyOwner {
        _pause();
    }

    function unpause() public payable onlyOwner {
        _unpause();
    }

    function upgradeKey(uint256[] calldata _assetIds) external nonReentrant whenNotPaused {
        require(_upgradeEnabled, "Real Agency: upgrade period has expired");

        for (uint256 i = 0; i < _assetIds.length; i++) {
            if (ERC721(_v1Contract).ownerOf(_assetIds[i]) != _msgSender()) revert notOwner();
            if (claimed[_assetIds[i]]) revert Claimed();
        }

        for (uint256 i = 0; i < _assetIds.length; i++) {
            // msg.sender will return this contract address when called by v1, _msgSender returns end user
            // contract owner sets vault address, make sure it can recieve erc721.
            ERC721(_v1Contract).transferFrom(_msgSender(), _v1VaultAddress, _assetIds[i]);

            emit Mint(_msgSender(), _assetIds[i]);
            _safeMint(_msgSender(), _assetIds[i]);
            claimed[_assetIds[i]] = true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _baseURIParam) external payable onlyOwner {
        _baseTokenURI = _baseURIParam;
    }

    function setV1Contract(address _v1) external payable onlyOwner {
        _v1Contract = _v1;
    }

    function setVaultAddress(address _v1vault) external payable onlyOwner {
        _v1VaultAddress = _v1vault;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external payable onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721){
        if(_transferProtection){
            if(_blockedTransfers[from] || _blockedTransfers[to]) revert blockedAddress();
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        if(_transferProtection){
            if(_blockedTransfers[from] || _blockedTransfers[to]) revert blockedAddress();
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721, IERC721){
        if(_transferProtection){
            if(_blockedTransfers[from] || _blockedTransfers[to]) revert blockedAddress();
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        if (_marketplaceProtection) {
            require(_approvedMarketplaces[to], "Real Agency: invalid Marketplace");
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        require(_approvedMarketplaces[operator], "Real Agency: invalid Marketplace");
        super.setApprovalForAll(operator, approved);
    }

    function setApprovedMarketplace(address market, bool approved) public payable onlyOwner {
        _approvedMarketplaces[market] = approved;
    }


    function setBlockedAddresses(address account, bool blocked) public payable onlyOwner {
        _blockedTransfers[account] = blocked;
    }

    function setUpgradeKeysEnabled(bool upgradeEnable) external payable onlyOwner {
        _upgradeEnabled  = upgradeEnable;
    }

    function setProtectionSettingsTransfer(bool transferProtect) external payable onlyOwner {
        _transferProtection  = transferProtect;
    }

    function setProtectionSettingsMarket(bool marketProtect) external payable onlyOwner {
        _marketplaceProtection = marketProtect;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}