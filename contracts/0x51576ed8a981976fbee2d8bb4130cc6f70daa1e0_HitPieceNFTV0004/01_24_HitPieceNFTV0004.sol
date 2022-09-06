// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../extensions/OwnableUpgradeable.sol";
import "../extensions/HPApprovedMarketplaceUpgradeable.sol";
import "../extensions/IHPMarketplaceMint.sol";
import "../extensions/IHPEvent.sol";
import "../extensions/IHPRoles.sol";
import "../extensions/NFTContractMetadataUpgradeable.sol";

// import "hardhat/console.sol";

contract HitPieceNFTV0004 is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable, ERC721PausableUpgradeable, OwnableUpgradeable, HPApprovedMarketplaceUpgradeable, IHPMarketplaceMint, NFTContractMetadataUpgradeable {
  bool private hasInitialized;
  address public mintAdmin;
  address public hpEventEmitterAddress;

  mapping(string => uint256) private _trackIdToTokenId;
  mapping(uint256 => string) private _tokenIdToTrackId;
  CountersUpgradeable.Counter private tokenCount;

  event Minted(uint256 indexed tokenId, string trackId);

  address private hpRolesContractAddress;
  bool private hasUpgradeInitialzed;

  function initialize(
    address _mintAdmin,
    address royaltyAddress,
    uint96 feeNumerator,
    string memory tokenName,
    string memory token,
    address[] memory marketplaces,
    string memory _contractMetadataURI,
    address _hpEventEmitterAddress,
    address _hpRolesContractAddress
    ) initializer public {
      require(hasInitialized == false, "This has already been initialized");
      hasInitialized = true;
      mintAdmin = _mintAdmin;
      hpEventEmitterAddress = _hpEventEmitterAddress;
      _baseContractURI = _contractMetadataURI;
      hpRolesContractAddress = _hpRolesContractAddress;
      hasUpgradeInitialzed = true;

      __ERC721_init(tokenName, token);
      __ERC721URIStorage_init_unchained();
      __ERC2981_init_unchained();
      __Ownable_init_unchained();
      __ERC721Pausable_init_unchained();

      _setDefaultRoyalty(royaltyAddress, feeNumerator);

      IHPEvent hpEventEmitter = IHPEvent(address(hpEventEmitterAddress));
      hpEventEmitter.setAllowedContracts(address(this));
      hpEventEmitter.emitNftContractInitialized(address(this));
    }
  
  function upgrader(address _hpRolesContractAddress) external {
    require(hasUpgradeInitialzed == false, "already upgraded");
    hasUpgradeInitialzed = true;
    hpRolesContractAddress = _hpRolesContractAddress;
  }

  function setHasUpgradeInitialized(bool upgraded) external onlyOwner {
    hasUpgradeInitialzed = upgraded;
  }

  function _mintTo(
    address to,
    address creatorRoyaltyAddress,
    uint96 feeNumerator,
    string memory uri,
    string memory trackId
  ) private returns (uint256) {
    require(
      _trackIdToTokenId[trackId] == 0 || _exists(0) == false,
      "Track already minted!"
    );
    uint256 newItemId = CountersUpgradeable.current(tokenCount);
    _mint(to, newItemId);
    _setTokenURI(newItemId, uri);
    _trackIdToTokenId[trackId] = newItemId;
    _tokenIdToTrackId[newItemId] = trackId;
    if (creatorRoyaltyAddress != address(0)) {
      _setTokenRoyalty(newItemId, creatorRoyaltyAddress, feeNumerator);
    }
    CountersUpgradeable.increment(tokenCount);

    IHPEvent hpEventEmitter = IHPEvent(address(hpEventEmitterAddress));
    hpEventEmitter.emitMintEvent(
        to, 
        address(this),
        newItemId,
        trackId);

    emit Minted(newItemId, trackId);
    return newItemId;
  }

  function adminMint(
    address to,
    address creatorRoyaltyAddress,
    uint96 feeNumerator,
    string memory uri,
    string memory trackId
  ) public {
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    require(mintAdmin == msg.sender || hpRoles.isAdmin(msg.sender) == true, "Admin rights required");
     _mintTo(to, creatorRoyaltyAddress, feeNumerator, uri, trackId);
  }

  function marketplaceMint(
    address to,
    address creatorRoyaltyAddress,
    uint96 feeNumerator,
    string memory uri,
    string memory trackId
  ) public override returns(uint256) {
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    require(hpRoles.isApprovedMarketplace(msg.sender) == true, "Only approved Marketplaces can call this function");
    uint256 newTokenId = _mintTo(to, creatorRoyaltyAddress, feeNumerator, uri, trackId);
    return newTokenId;
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable) {
    super.setApprovalForAll(operator, approved);

    IHPEvent hpEventEmitter = IHPEvent(address(hpEventEmitterAddress));
    hpEventEmitter.emitSetApprovedForAll(
      address(this),
      operator,
      approved
    );
  }

  function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable) {
    super.approve(operator, tokenId);

    IHPEvent hpEventEmitter = IHPEvent(address(hpEventEmitterAddress));
    hpEventEmitter.emitApproved(
      address(this),
      operator,
      tokenId
    );
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function burn(uint256 tokenId) public {
    require(msg.sender == ownerOf(tokenId), "You must be the owner to burn token");
    _burn(tokenId);
  }

  function getTokenIdFromTrackId(string memory trackId)
    public
    view
    returns (uint256)
  {
    return _trackIdToTokenId[trackId];
  }

  function _isTokenOwner(address requester, uint256 tokenId)
    private
    view
    returns (bool)
  {
    if (ownerOf(tokenId) == requester) {
      return true;
    }
    return false;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // ERC2981Upgradeable overrides
  function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setMintAdmin(address newAdmin) public onlyOwner {
    mintAdmin = newAdmin;
  }

  function isApprovedForAll(address owner, address operator) override(ERC721Upgradeable) public view returns (bool) {
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    if (hpRoles.isApprovedMarketplace(operator)) {
        return true;
    }
    return ERC721Upgradeable.isApprovedForAll(owner, operator);
  }

  // ERC721 Overrides
  function tokenURI(uint256 tokenId) public view override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
    return super.tokenURI(tokenId);
  } 

  function _burn(uint256 tokenId) internal override(ERC721URIStorageUpgradeable, ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
    delete _trackIdToTokenId[_tokenIdToTrackId[tokenId]];
    delete _tokenIdToTrackId[tokenId];
    super._burn(tokenId);
  }

  // Pausable 
  function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721PausableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Upgradeable) {

    IHPEvent hpEventEmitter = IHPEvent(address(hpEventEmitterAddress));
    hpEventEmitter.emitTokenTransferred(
      from,
      to,
      address(this),
      tokenId
    );

    super._afterTokenTransfer(from, to, tokenId);
  }

  // Royalties
  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    require(mintAdmin == msg.sender || hpRoles.isAdmin(msg.sender) == true, "Admin rights required");
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }
}