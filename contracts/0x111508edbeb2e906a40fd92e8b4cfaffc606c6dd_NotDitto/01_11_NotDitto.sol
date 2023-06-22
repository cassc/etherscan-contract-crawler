// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMetadata.sol";

//  @title: NOT DITTO

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/////////////////////////@@///////////////////////////@@////////////////////////
/////////////////////////@@//////////////////////////@@@////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

contract NotDitto is ERC721AQueryable, Ownable, ReentrancyGuard, IERC2981 {
  // ._. Errors ._.

  error SoldOut();
  error SaleInactive();
  error MintAllowanceSurpassed();
  error TransferPaused();
  error TransferControlRevoked();
  error NotOwner();
  error TokenIdHasMorphed();
  error MorphDataClaimed();
  error MorphInactive();
  error UnmorphInactive();
  error MorphCooldown();
  error SenderNotMorpher();
  error TokenHasNotMorphed();

  // ._. Events ._.

  event Morphed(
    uint32 indexed tokenId,
    address indexed morphAddress,
    uint32 indexed morphId
  );
  event MorphedSol(uint32 indexed tokenId, string indexed morphAddressSol);
  event Unmorphed(uint32 indexed tokenId);

  // ._. Metadata ._.

  string public baseTokenURI;
  address public metadataAddress;

  // ._. Sale Status ._.

  uint256 public maxSupply = 4444;
  uint256 public teamSupply = 444;
  uint256 public maxPerTransaction = 3;
  bool public isSaleActive = false;

  // ._. Transfer Status ._.

  bool public isTransferPaused = false;
  bool public isTransferControlRevoked = false;

  // ._. Royalties ._.

  address public royaltyAddress;
  uint256 public royaltyPercent = 0;

  // ._. Morph ._.

  enum Chains {
    ETH,
    SOL
  }

  struct MorphData {
    uint32 morphId;
    address morphAddress;
    string morphAddressSol;
    uint256 morphTimestamp;
    Chains morphChain;
  }
  mapping(uint32 => MorphData) public tokenIdToMorphData;
  mapping(bytes32 => uint32) public morphHashToTokenId;

  uint256 public morphCooldown = 172800;
  bool public isMorphActive = true;
  bool public isUnmorphActive = true;
  address public morpherAddress;

  modifier onlyMorpher() {
    if (msg.sender != morpherAddress) revert SenderNotMorpher();
    _;
  }

  // ._. Constructors ._.

  constructor(string memory _baseTokenURI) ERC721A("NOT DITTO", "NOTDITTO") {
    baseTokenURI = _baseTokenURI;
    royaltyAddress = msg.sender;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  // ._. Mint ._.

  function mint(uint256 _amount) external nonReentrant {
    if (!isSaleActive) revert SaleInactive();
    if (totalSupply() + _amount > maxSupply - teamSupply) revert SoldOut();
    if (_amount > maxPerTransaction) revert MintAllowanceSurpassed();

    _safeMint(msg.sender, _amount);
  }

  function mintTeam(address _to, uint256 _amount) external onlyOwner {
    if (_amount > teamSupply) revert SoldOut();
    teamSupply -= _amount;

    _safeMint(_to, _amount);
  }

  function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
    maxPerTransaction = _maxPerTransaction;
  }

  function setTeamSupply(uint256 _teamSupply) external onlyOwner {
    teamSupply = _teamSupply;
  }

  function toggleSale() external onlyOwner {
    isSaleActive = !isSaleActive;
  }

  // ._. Morph ._.

  function morph(
    uint32 _tokenId,
    address _morphAddress,
    uint32 _morphId
  ) external {
    if (!isMorphActive) revert MorphInactive();
    if (ownerOf(_tokenId) != msg.sender) revert NotOwner();

    bytes32 morphHash = keccak256(abi.encodePacked(_morphAddress, _morphId));

    if (morphHashToTokenId[morphHash] != 0) revert MorphDataClaimed();
    if (address(tokenIdToMorphData[_tokenId].morphAddress) != address(0))
      revert TokenIdHasMorphed();
    if (bytes(tokenIdToMorphData[_tokenId].morphAddressSol).length != 0)
      revert TokenIdHasMorphed();

    morphHashToTokenId[morphHash] = _tokenId;
    tokenIdToMorphData[_tokenId] = MorphData({
      morphId: _morphId,
      morphAddress: _morphAddress,
      morphAddressSol: "",
      morphTimestamp: block.timestamp,
      morphChain: Chains.ETH
    });

    emit Morphed(_tokenId, _morphAddress, _morphId);
  }

  function morphSol(uint32 _tokenId, string memory _morphAddressSol) external {
    if (!isMorphActive) revert MorphInactive();
    if (ownerOf(_tokenId) != msg.sender) revert NotOwner();

    bytes32 morphHash = keccak256(abi.encodePacked(_morphAddressSol));

    if (morphHashToTokenId[morphHash] != 0) revert MorphDataClaimed();
    if (address(tokenIdToMorphData[_tokenId].morphAddress) != address(0))
      revert TokenIdHasMorphed();
    if (bytes(tokenIdToMorphData[_tokenId].morphAddressSol).length != 0)
      revert TokenIdHasMorphed();

    morphHashToTokenId[morphHash] = _tokenId;
    tokenIdToMorphData[_tokenId] = MorphData({
      morphId: 0,
      morphAddress: address(0),
      morphAddressSol: _morphAddressSol,
      morphTimestamp: block.timestamp,
      morphChain: Chains.SOL
    });

    emit MorphedSol(_tokenId, _morphAddressSol);
  }

  function unmorph(uint32 _tokenId) external {
    if (!isUnmorphActive) revert UnmorphInactive();
    if (ownerOf(_tokenId) != msg.sender) revert NotOwner();
    if (
      block.timestamp <
      tokenIdToMorphData[_tokenId].morphTimestamp + morphCooldown
    ) revert MorphCooldown();

    bytes32 morphHash = keccak256(
      abi.encodePacked(
        tokenIdToMorphData[_tokenId].morphAddress,
        tokenIdToMorphData[_tokenId].morphId
      )
    );

    if (morphHashToTokenId[morphHash] == 0) revert TokenHasNotMorphed();

    delete morphHashToTokenId[morphHash];
    delete tokenIdToMorphData[_tokenId];

    emit Unmorphed(_tokenId);
  }

  function unmorphSol(uint32 _tokenId) external {
    if (!isUnmorphActive) revert UnmorphInactive();
    if (ownerOf(_tokenId) != msg.sender) revert NotOwner();
    if (
      block.timestamp <
      tokenIdToMorphData[_tokenId].morphTimestamp + morphCooldown
    ) revert MorphCooldown();

    bytes32 morphHash = keccak256(
      abi.encodePacked(tokenIdToMorphData[_tokenId].morphAddressSol)
    );

    if (morphHashToTokenId[morphHash] == 0) revert TokenHasNotMorphed();

    delete morphHashToTokenId[morphHash];
    delete tokenIdToMorphData[_tokenId];

    emit Unmorphed(_tokenId);
  }

  function toggleMorph() external onlyOwner {
    isMorphActive = !isMorphActive;
  }

  function toggleUnmorph() external onlyOwner {
    isUnmorphActive = !isUnmorphActive;
  }

  function setTokenIdToMorphData(
    uint32 _tokenId,
    address _morphAddress,
    uint32 _morphId,
    string memory _morphAddressSol,
    Chains _morphChain
  ) external onlyMorpher {
    tokenIdToMorphData[_tokenId] = MorphData({
      morphId: _morphId,
      morphAddress: _morphAddress,
      morphAddressSol: _morphAddressSol,
      morphTimestamp: block.timestamp,
      morphChain: _morphChain
    });
  }

  function setMorphHashToTokenId(bytes32 _morphHash, uint32 _tokenId)
    external
    onlyMorpher
  {
    morphHashToTokenId[_morphHash] = _tokenId;
  }

  function setMorphCooldown(uint256 _morphCooldown) external onlyOwner {
    morphCooldown = _morphCooldown;
  }

  function setMorpher(address _morpherAddress) external onlyOwner {
    morpherAddress = _morpherAddress;
  }

  // ._. Metadata ._.

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    if (address(metadataAddress) != address(0)) {
      if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
      return IMetadata(metadataAddress).tokenURI(_tokenId);
    }
    return super.tokenURI(_tokenId);
  }

  function dittoURI(uint256 _tokenId)
    public
    view
    virtual
    returns (string memory)
  {
    MorphData memory morphData = tokenIdToMorphData[uint32(_tokenId)];
    if (
      address(morphData.morphAddress) != address(0) &&
      morphData.morphChain == Chains.ETH
    ) {
      if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
      return IMetadata(morphData.morphAddress).tokenURI(morphData.morphId);
    } else if (
      bytes(morphData.morphAddressSol).length != 0 &&
      morphData.morphChain == Chains.SOL
    ) {
      if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
      return morphData.morphAddressSol;
    }

    return super.tokenURI(_tokenId);
  }

  function setMetadataAddress(address _metadataAddress) external onlyOwner {
    metadataAddress = _metadataAddress;
  }

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  // ._. Transfer Control ._.

  function _beforeTokenTransfers(
    address,
    address,
    uint256 startTokenId,
    uint256 quantity
  ) internal view override {
    if (isTransferPaused) revert TransferPaused();
  }

  function toggleTransfer() external onlyOwner {
    if (isTransferControlRevoked) revert TransferControlRevoked();
    isTransferPaused = !isTransferPaused;
  }

  function revokeTransferControl() external onlyOwner {
    isTransferPaused = false;
    isTransferControlRevoked = true;
  }

  // ._. Misc ._.

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return (royaltyAddress, (salePrice * royaltyPercent) / 100);
  }

  function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
    royaltyAddress = _royaltyAddress;
  }

  function setRoyaltyPercent(uint256 _royaltyPercent) external onlyOwner {
    royaltyPercent = _royaltyPercent;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, IERC721A, IERC165)
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  }
}