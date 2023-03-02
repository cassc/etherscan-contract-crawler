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

import "./DCNT721A.sol";

/// @title template NFT contract
contract ZKEdition is DCNT721A {

  address public zkVerifier;

  /// ============ Constructor ============

  function initialize(
    address _owner,
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig,
    TokenGateConfig memory _tokenGateConfig,
    address _metadataRenderer,
    address _splitMain,
    address _zkVerifier
  ) public initializer {
    _transferOwnership(_owner);
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _name = _editionConfig.name;
    _symbol = _editionConfig.symbol;
    _currentIndex = _startTokenId();
    MAX_TOKENS = _editionConfig.maxTokens;
    tokenPrice = _editionConfig.tokenPrice;
    maxTokenPurchase = _editionConfig.maxTokenPurchase;
    saleStart = _editionConfig.saleStart;
    saleEnd = _editionConfig.saleEnd;
    royaltyBPS = _editionConfig.royaltyBPS;
    payoutAddress = _editionConfig.payoutAddress;
    hasAdjustableCap = _editionConfig.hasAdjustableCap;
    isSoulbound = _editionConfig.isSoulbound;
    parentIP = _metadataConfig.parentIP;
    splitMain = _splitMain;
    tokenGateConfig = _tokenGateConfig;
    presaleMerkleRoot = _editionConfig.presaleMerkleRoot;
    presaleStart = _editionConfig.presaleStart;
    presaleEnd = _editionConfig.presaleEnd;

    zkVerifier = _zkVerifier;

    if (
      _metadataRenderer != address(0) &&
      _metadataConfig.metadataRendererInit.length > 0
    ) {
      metadataRenderer = _metadataRenderer;
      IMetadataRenderer(_metadataRenderer).initializeWithData(
        _metadataConfig.metadataRendererInit
      );
    } else {
      _contractURI = _metadataConfig.contractURI;
      baseURI = _metadataConfig.metadataURI;
    }
  }

  /// @notice allows someone to claim an nft with a valid zk proof
  function zkClaim(address recipient) external {
    require(msg.sender == zkVerifier, "Only zkVerifier can call");
    uint256 mintIndex = _nextTokenId();
    require(
      mintIndex + 1 <= MAX_TOKENS,
      "Purchase would exceed max supply"
    );

    _safeMint(recipient, 1);
    emit Minted(recipient, mintIndex);
  }

  function setZKVerifier(address _zkVerifier) external onlyOwner {
    zkVerifier = _zkVerifier;
  }
}