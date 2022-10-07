// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import "./erc721a/ERC721A.sol";
import "./interfaces/IMetadataRenderer.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./storage/EditionConfig.sol";
import "./storage/MetadataConfig.sol";
import "./utils/Splits.sol";

/// @title template NFT contract
contract DCNT721A is ERC721A, Initializable, Ownable, Splits {
  /// ============ Immutable storage ============

  /// ============ Mutable storage ============

  uint256 public MAX_TOKENS;
  uint256 public tokenPrice;
  uint256 public maxTokenPurchase;

  bool public saleIsActive = false;
  string public baseURI;
  address public metadataRenderer;
  uint256 public royaltyBPS;

  address public splitMain;
  address public splitWallet;

  /// ============ Events ============

  /// @notice Emitted after a successful token claim
  /// @param sender recipient of NFT mint
  /// @param tokenId_ of token minted
  event Minted(address sender, uint256 tokenId_);

  /// ============ Constructor ============

  function initialize(
    address _owner,
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig,
    address _metadataRenderer,
    address _splitMain
  ) public initializer {
    _transferOwnership(_owner);
    _name = _editionConfig.name;
    _symbol = _editionConfig.symbol;
    _currentIndex = _startTokenId();
    MAX_TOKENS = _editionConfig.maxTokens;
    tokenPrice = _editionConfig.tokenPrice;
    maxTokenPurchase = _editionConfig.maxTokenPurchase;
    royaltyBPS = _editionConfig.royaltyBPS;
    splitMain = _splitMain;

    if (
      _metadataRenderer != address(0) &&
      _metadataConfig.metadataRendererInit.length > 0
    ) {
      metadataRenderer = _metadataRenderer;
      IMetadataRenderer(_metadataRenderer).initializeWithData(
        _metadataConfig.metadataRendererInit
      );
    } else {
      baseURI = _metadataConfig.metadataURI;
    }
  }

  function mint(uint256 numberOfTokens) external payable {
    uint256 mintIndex = totalSupply();
    require(saleIsActive, "Sale must be active to mint");
    require(
      mintIndex + numberOfTokens <= MAX_TOKENS,
      "Purchase would exceed max supply"
    );
    require(mintIndex <= MAX_TOKENS, "SOLD OUT");
    require(msg.value >= (tokenPrice * numberOfTokens), "Insufficient funds");
    if ( maxTokenPurchase != 0 ) {
      require(numberOfTokens <= maxTokenPurchase, "Exceeded max number per mint");
    }

    _safeMint(msg.sender, numberOfTokens);
    for (uint256 i = 0; i < numberOfTokens; i++) {
      emit Minted(msg.sender, mintIndex++);
    }
  }

  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function withdraw() external onlyOwner {
    require(
      _getSplitWallet() == address(0),
      "Cannot withdraw with an active split"
    );
    payable(msg.sender).transfer(address(this).balance);
  }

  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setMetadataRenderer(address _metadataRenderer) external onlyOwner {
    metadataRenderer = _metadataRenderer;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    if (metadataRenderer != address(0)) {
      return IMetadataRenderer(metadataRenderer).tokenURI(tokenId);
    }
    return super.tokenURI(tokenId);
  }

  // save some for creator
  function reserveDCNT(uint256 numReserved) external onlyOwner {
    uint256 supply = totalSupply();
    require(
      supply + numReserved < MAX_TOKENS,
      "Purchase would exceed max supply"
    );
    for (uint256 i = 0; i < numReserved; i++) {
      _safeMint(msg.sender, supply + i + 1);
    }
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");

    if (splitWallet != address(0)) {
      receiver = splitWallet;
    } else {
      receiver = owner();
    }

    uint256 royaltyPayment = (salePrice * royaltyBPS) / 10_000;

    return (receiver, royaltyPayment);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A)
    returns (bool)
  {
    return
      interfaceId == 0x2a55205a || // ERC2981 interface ID for ERC2981.
      super.supportsInterface(interfaceId);
  }

  function _getSplitMain() internal virtual override returns (address) {
    return splitMain;
  }

  function _getSplitWallet() internal virtual override returns (address) {
    return splitWallet;
  }

  function _setSplitWallet(address _splitWallet) internal virtual override {
    splitWallet = _splitWallet;
  }
}