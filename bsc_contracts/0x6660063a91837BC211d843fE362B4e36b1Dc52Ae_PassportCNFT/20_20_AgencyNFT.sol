// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../common/ERC721URIStorageEnumerable.sol";
import "../common/IAgency.sol";
import "../common/OwnPauseBase.sol";

contract AgencyNFT is OwnPauseBase, ERC721URIStorageEnumerable {
  // First tokenId begins from 1
  // Indicate the total number of minted tokens (not subtracted by burn)
  uint256 public _tokenId;

  uint256 public _burnCount; // count the number of burnt tokens

  bool public _tokenTransferPaused;

  IAgency public _agency;

  // "tokenAnimationURL" and "tokenImageURL" can be empty str
  event EvtMintToken(
    address receiver,
    uint256 tokenId,
    string agencyId,
    string tokenAnimationURL,
    string metadataType,
    string tokenImageURL
  );
  event EvtMintManyTokens(
    address receiver,
    uint256[] tokenIdList,
    string agencyId
  );
  event EvtMassMint(
    address[] receiverList,
    uint256[] tokenIdList,
    string agencyId
  );

  event EvtBurnToken(address tokenOwner, uint256 tokenId);
  event EvtAdminBurnToken(address adminAddress, uint256 tokenId);
  event EvtAdminBurnManyTokens(address adminAddress, uint256[] tokenIdList);
  event EvtSetAgency(address agency);
  event EvtSetTokenTransferPaused(bool tokenTransferPaused);
  event EvtAdminTransferToken(address tokenOwner, address to, uint256 tokenId);
  event EvtAdminTransferTokenMany(
    uint256[] tokenIdList,
    address[] receiverList
  );
  event EvtTransfer(address from, address to, uint256 tokenId);
  event EvtTransferMany(
    address from,
    address[] receiverList,
    uint256[] tokenIdList
  );
  event EvtSetTokenURI(uint256 tokenId, string tokenURI);

  constructor(string memory name_, string memory symbol_)
    ERC721(name_, symbol_)
  {
    _tokenTransferPaused = false;
  }

  // Apply _tokenTransferPaused for token transfer
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);

    require(_tokenTransferPaused == false, "token transfer paused");
  }

  function setTokenTransferPaused(bool tokenTransferPaused_) external isOwner {
    _tokenTransferPaused = tokenTransferPaused_;
    emit EvtSetTokenTransferPaused(tokenTransferPaused_);
  }

  function setAgency(IAgency agency_) external isOwner {
    require(address(agency_) != address(0), "Invalid agency_");
    _agency = agency_;
    emit EvtSetAgency(address(agency_));
  }

  function tokenExists(uint256 tokenId_) public view returns (bool) {
    return _exists(tokenId_);
  }

  function burnToken(uint256 tokenId_) external {
    require(ownerOf(tokenId_) == _msgSender(), "Not token owner");
    _burn(tokenId_);
    _burnCount += 1;
    emit EvtBurnToken(_msgSender(), tokenId_);
  }

  function adminBurnToken(uint256 tokenId_) external isAuthorized {
    _burn(tokenId_);
    _burnCount += 1;
    emit EvtAdminBurnToken(_msgSender(), tokenId_);
  }

  function adminBurnManyTokens(uint256[] memory tokenIdList_)
    external
    isAuthorized
  {
    for (uint256 i = 0; i < tokenIdList_.length; i++) {
      _burn(tokenIdList_[i]);
      _burnCount += 1;
    }
    emit EvtAdminBurnManyTokens(_msgSender(), tokenIdList_);
  }

  // tokenURI of the minted token will be set externally by the event-listener
  function setTokenURI(uint256 tokenId_, string memory tokenURI_) external {
    require(
      checkAuthorized(_msgSender()) || ownerOf(tokenId_) == _msgSender(),
      "not authorized or not token owner"
    );

    _setTokenURI(tokenId_, tokenURI_);
    emit EvtSetTokenURI(tokenId_, tokenURI_);
  }

  // "agencyId_" will be included in the event for metadata (name, description, animation_url, image) build.
  // If it is empty string, the default agencyId will be used but with empty veriSign (i.e. unverified passport token)
  // The "tokenAnimationURL_" is optional and will be included in the emitted EvtMintToken for the event-listener to use
  // The "tokenImageURL_" is optional and will be included in the emitted EvtMintToken for the event-listener to use
  function mintToken(
    address receiver_,
    string memory agencyId_,
    string memory tokenAnimationURL_, // custom animation_url (can be empty string)
    string memory metadataType_, // "default", "hotel", "flight", "activity" for stamp. Empty string for passport
    string memory tokenImageURL_ // custom image_url (can be empty string)
  ) external isAuthorized returns (uint256) {
    if (bytes(metadataType_).length > 0) {
      require(
        _agency._metadataTypeStatusList(metadataType_) == true,
        "Unsupported metadataType_"
      );
    }

    _tokenId = _tokenId + 1;
    _safeMint(receiver_, _tokenId, "");
    _agency.setTokenIdAgencyInfo(_tokenId, _agency.safeGetAgencyId(agencyId_));

    emit EvtMintToken(
      receiver_,
      _tokenId,
      _agency.safeGetAgencyId(agencyId_),
      tokenAnimationURL_,
      metadataType_,
      tokenImageURL_
    );
    return _tokenId;
  }

  // Mint many tokens to 1 wallet
  // "agencyId_" will be included in the event for metadata (name, description, animation_url, image) build.
  // If it is empty string, the default agencyId will be used but with empty veriSign (i.e. unverified passport token)
  function mintManyTokens(
    address receiver_,
    uint256 tokenAmount_,
    string memory agencyId_
  ) external isAuthorized returns (uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](tokenAmount_);

    for (uint256 i = 0; i < tokenAmount_; i++) {
      _tokenId = _tokenId + 1;
      _safeMint(receiver_, _tokenId, "");
      _agency.setTokenIdAgencyInfo(
        _tokenId,
        _agency.safeGetAgencyId(agencyId_)
      );

      tokenIds[i] = _tokenId;
    }

    emit EvtMintManyTokens(
      receiver_,
      tokenIds,
      _agency.safeGetAgencyId(agencyId_)
    );
    return tokenIds;
  }

  // Mint 1 token to 1 wallet specified in the receiverList_
  // "agencyId_" will be included in the event for metadata (name, description, animation_url, image) build.
  // If it is empty string, the default agencyId will be used but with empty veriSign (i.e. unverified passport token)
  function massMint(address[] memory receiverList_, string memory agencyId_)
    external
    isAuthorized
  {
    require(receiverList_.length > 0, "Empty receiverList_");

    uint256[] memory tokenIds = new uint256[](receiverList_.length);
    for (uint256 i = 0; i < receiverList_.length; i++) {
      _tokenId = _tokenId + 1;
      _safeMint(receiverList_[i], _tokenId, "");
      _agency.setTokenIdAgencyInfo(
        _tokenId,
        _agency.safeGetAgencyId(agencyId_)
      );

      tokenIds[i] = _tokenId;
    }

    emit EvtMassMint(
      receiverList_,
      tokenIds,
      _agency.safeGetAgencyId(agencyId_)
    );
  }

  function adminTransferToken(uint256 tokenId_, address receiver_)
    public
    isAuthorized
  {
    require(_exists(tokenId_), "Token not exist");

    address tokenOwner = ownerOf(tokenId_);
    _safeTransfer(tokenOwner, receiver_, tokenId_, "");

    emit EvtAdminTransferToken(tokenOwner, receiver_, tokenId_);
  }

  function adminTransferTokenMany(
    uint256[] memory tokenIdList_,
    address[] memory receiverList_
  ) public isAuthorized {
    require(
      tokenIdList_.length == receiverList_.length,
      "tokenIdList_ and receiverList_ not same length"
    );

    for (uint256 i = 0; i < receiverList_.length; i++) {
      require(_exists(tokenIdList_[i]), "Token not exist");
      _safeTransfer(
        ownerOf(tokenIdList_[i]),
        receiverList_[i],
        tokenIdList_[i],
        ""
      );
    }

    emit EvtAdminTransferTokenMany(tokenIdList_, receiverList_);
  }

  function transfer(uint256 tokenId_, address receiver_) external {
    require(_exists(tokenId_), "Token not exist");
    // safeTransfer has a check if token owner
    _safeTransfer(_msgSender(), receiver_, tokenId_, "");

    emit EvtTransfer(_msgSender(), receiver_, tokenId_);
  }

  function transferMany(
    uint256[] memory tokenIdList_,
    address[] memory receiverList_
  ) external {
    require(
      tokenIdList_.length == receiverList_.length,
      "tokenIdList_ and receiverList_ not same length"
    );

    for (uint256 i = 0; i < receiverList_.length; i++) {
      require(_exists(tokenIdList_[i]), "Token not exist");
      // safeTransfer has a check if token owner
      _safeTransfer(_msgSender(), receiverList_[i], tokenIdList_[i], "");
    }

    emit EvtTransferMany(_msgSender(), receiverList_, tokenIdList_);
  }
}