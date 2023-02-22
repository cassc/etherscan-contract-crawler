// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../extensions/IHPMarketplaceMintV0002.sol";
import "../extensions/OwnableUpgradeable.sol";
import "../extensions/HPApprovedMarketplaceUpgradeable.sol";
import "../extensions/IHPMarketplaceMint.sol";
import "../extensions/IHPEvent.sol";
import "../extensions/IHPRoles.sol";
import "../extensions/NFTContractMetadataUpgradeable.sol";

// import "hardhat/console.sol";

contract HitPieceNFTV0013 is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable, ERC721PausableUpgradeable, OwnableUpgradeable, HPApprovedMarketplaceUpgradeable, IHPMarketplaceMintV0002, NFTContractMetadataUpgradeable {
  bool private hasInitialized;
  address public mintAdmin;
  address public hpEventEmitterAddress;

  mapping(string => uint256) private _trackIdToTokenId;
  mapping(uint256 => string) private _tokenIdToTrackId;
  CountersUpgradeable.Counter private tokenCount;

  event Minted(uint256 indexed tokenId, string trackId);

  address private hpRolesContractAddress;
  bool private hasUpgradeInitialzed;
  uint256 public MAX_SUPPLY;
  bool private isSeriesNft;
  string private baseTokenURI;

  function initialize(
    address _mintAdmin,
    address royaltyAddress,
    uint96 feeNumerator,
    string memory tokenName,
    string memory token,
    address[] memory marketplaces,
    string memory _contractMetadataURI,
    address _hpEventEmitterAddress,
    address _hpRolesContractAddress,
    uint256 _maxSupply,
    bool _isSeriesNft,
    string memory _baseTokenURI
    ) initializer public {
      require(hasInitialized == false, "This has already been initialized");
      hasInitialized = true;
      mintAdmin = _mintAdmin;
      hpEventEmitterAddress = _hpEventEmitterAddress;
      _baseContractURI = _contractMetadataURI;
      hpRolesContractAddress = _hpRolesContractAddress;
      hasUpgradeInitialzed = true;
      MAX_SUPPLY = _maxSupply;
      isSeriesNft = _isSeriesNft;
      baseTokenURI = _baseTokenURI;

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
    require(MAX_SUPPLY == 0 || newItemId < MAX_SUPPLY, "Already minted all the tokens.");
    _mint(to, newItemId);
    if (!isSeriesNft) {
      _setTokenURI(newItemId, uri);
    }
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

  function marketplaceTransfer(
    address from,
    address to,
    uint tokenId
  ) public override {
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    require(hpRoles.isApprovedMarketplace(msg.sender) == true, "Only approved Marketplaces can call this function");

    _transfer(from, to, tokenId);
  }

  function getTotalSupply() public view returns (uint256) {
    return CountersUpgradeable.current(tokenCount);
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    MAX_SUPPLY = _maxSupply;
  }

  function setIsSeriesNft(bool _isSeriesNft) public onlyOwner {
    isSeriesNft = _isSeriesNft;
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
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
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    require(msg.sender == ownerOf(tokenId) || hpRoles.isAdmin(msg.sender) == true, "You must be the owner to burn token");
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

  function _seriesBaseURI() internal view returns (string memory) {
    return string(abi.encodePacked(baseTokenURI, "/"));
  }

  // ERC721 Overrides
  function tokenURI(uint256 tokenId) public view override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
    require(_exists(tokenId), "Token ID doesn't exist");

    if (isSeriesNft && bytes(baseTokenURI).length > 0) {
      return string(abi.encodePacked(_seriesBaseURI(), _toString(tokenId)));
    }

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

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(tokenId, _tokenURI);
  }

  function getHpRoles() public view returns (address) {
    return hpRolesContractAddress;
  }

  function setHpRoles(address _hpRolesContractAddress) public onlyOwner {
    hpRolesContractAddress = _hpRolesContractAddress;
  }

  function overrideOwnership(address newOwner) public { 
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    require(hpRoles.isAdmin(msg.sender) == true, "Admin rights required");

    _transferOwnership(newOwner);
  }

  function _toString(uint256 value) internal pure returns (string memory ptr) {
    assembly {
      ptr := add(mload(0x40), 128)
      mstore(0x40, ptr)
      let end := ptr
      for {
        let temp := value
        ptr := sub(ptr, 1)
        mstore8(ptr, add(48, mod(temp, 10)))
        temp := div(temp, 10)
      } temp {
        temp := div(temp, 10)
      } {
        ptr := sub(ptr, 1)
        mstore8(ptr, add(48, mod(temp, 10)))
      }
      let length := sub(end, ptr)
      ptr := sub(ptr, 32)
      mstore(ptr, length)
    }
  }

}