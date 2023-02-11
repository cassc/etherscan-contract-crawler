// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./OwnPauseBase.sol";

contract Agency is OwnPauseBase {
  string public _defaultAgencyId = "trvl.com";
  string public _defaultAgencyVeriSign = "Verified by TRVL";

  string public _agencyOwnerContractName;
  address public _agencyOwnerContractAddress;

  uint256 public _maxMintedTokensPerAgency;

  // No need to include AgencyMetadata here because token's metadata can be retrieved via tokenURI() method
  struct AgencyInfo {
    string id;
    string veriSign; // verification signature. Empty if the token is not yet verified
    uint256 timestamp; // minted or updated time of the token
  }

  struct AgencyMetadata {
    string name; // Travel ABC #{tokenId}
    string description; // This is travel ABC agency
    string animation_url; // https://link-to-template-animation_url
    string image; // https://link-to-template-image_url
  }

  struct AgencyMetadataAttributes {
    string trait_type;
    string value;
  }

  AgencyMetadata public _defaultAgencyMetadata;

  // tokenId => AgencyInfo
  mapping(uint256 => AgencyInfo) public _tokenId_agencyInfo;

  // agencyId => tokenId list
  // if ownerOf(tokenId) is address(0), token is invalid
  mapping(string => uint256[]) public _agencyId_tokenIdList;

  // agencyId => maxAllowableMintedTokens
  mapping(string => uint256) public _agencyId_maxAllowableMintedTokens;

  // agencyId => veriSign
  mapping(string => string) public _agencyId_agencyVeriSign;
  bytes32[] public _agencyIdList;
  // count the number of registered agencies. It can be diff from _agencyIdList.length due to removeAgencyInfo()
  uint256 public _agencyCount;

  // For Passport
  // agencyId => AgencyMetadata
  mapping(string => AgencyMetadata) public _agencyId_agencyMetadata;

  // For Stamp
  // agencyId => metadataType => AgencyMetadata
  mapping(string => mapping(string => AgencyMetadata))
    public _agencyId_agencyMultiMetadata;

  // metadataType => bool
  // Used to check if metadata type is supported or not
  mapping(string => bool) public _metadataTypeStatusList; // currently-supported types: "hotel", "flight", "activity"

  // agencyId => AgencyMetadataAttributes
  mapping(string => AgencyMetadataAttributes[])
    public _agencyId_agencyMetadataAttributes;

  event EvtSetAgencyMaxAllowableMintedTokens(
    string agencyId_,
    uint256 agencyMaxAllowableMintedTokens_
  );
  event EvtSetMetadataTypeStatus(string metadataType_, bool allowed_);
  event EvtSetDefaultAgencyInfo(string id, string veriSign);
  event EvtSetDefaultAgencyMetadata(
    string defaultAgencyName,
    string defaultAgencyDescription,
    string defaultAgencyImage,
    string defaultAgencyAnimation
  );
  event EvtRegisterAgencyInfo(string agencyId, string agencyVeriSign);
  event EvtUpdateAgencyInfo(string agencyId, string agencyVeriSign);
  event EvtRemoveAgencyInfo(string agencyId);
  event EvtSetAgencyMetadata(
    string agencyId,
    string name,
    string description,
    string animation_url,
    string image
  );
  event EvtSetAgencyMultiMetadata(
    string agencyId,
    string metadataType,
    string name,
    string description,
    string animation_url,
    string image
  );
  event EvtAddAgencyMetadataAttribute(
    string agencyId,
    string trait_type,
    string value
  );
  event EvtUpdateAgencyMetadataAttribute(
    string agencyId,
    string trait_type,
    string value
  );
  event EvtUpdateOrVerifyTokenIdAgencyInfo(uint256 tokenId, string agencyId);
  event EvtUpdateOrVerifyManyTokenIdsAgencyInfo(
    uint256[] tokenIds,
    string agencyId
  );

  constructor(
    uint256 maxMintedTokensPerAgency_,
    string memory defaultAgencyName_,
    string memory defaultAgencyDescription_,
    string memory defaultAgencyAnimation_,
    string memory defaultAgencyImage_
  ) {
    _maxMintedTokensPerAgency = maxMintedTokensPerAgency_;

    _defaultAgencyMetadata = AgencyMetadata(
      defaultAgencyName_,
      defaultAgencyDescription_,
      defaultAgencyAnimation_,
      defaultAgencyImage_
    );

    // Init supported metadata types
    _metadataTypeStatusList["default"] = true; // default for the different metadata types
    _metadataTypeStatusList["hotel"] = true;
    _metadataTypeStatusList["flight"] = true;
    _metadataTypeStatusList["activity"] = true;
  }

  function setOwnerContract(
    string memory agencyOwnerContractName_,
    address agencyOwnerContractAddress_
  ) external isOwner {
    require(
      agencyOwnerContractAddress_ != address(0),
      "Invalid agencyOwnerContractAddress_"
    );
    _agencyOwnerContractName = agencyOwnerContractName_;
    _agencyOwnerContractAddress = agencyOwnerContractAddress_;
  }

  function setMaxMintedTokensPerAgency(uint256 maxMintedTokensPerAgency_)
    external
    isOwner
  {
    _maxMintedTokensPerAgency = maxMintedTokensPerAgency_;
  }

  function setDefaultAgencyMetadata(
    string memory defaultAgencyName_,
    string memory defaultAgencyDescription_,
    string memory defaultAgencyImage_,
    string memory defaultAgencyAnimation_
  ) external isOwner {
    _defaultAgencyMetadata.name = defaultAgencyName_;
    _defaultAgencyMetadata.description = defaultAgencyDescription_;
    _defaultAgencyMetadata.image = defaultAgencyImage_;
    _defaultAgencyMetadata.animation_url = defaultAgencyAnimation_;

    emit EvtSetDefaultAgencyMetadata(
      defaultAgencyName_,
      defaultAgencyDescription_,
      defaultAgencyImage_,
      defaultAgencyAnimation_
    );
  }

  function setDefaultAgencyInfo(
    string memory defaultAgencyId_,
    string memory defaultAgencyVeriSign_
  ) external isOwner {
    _defaultAgencyId = defaultAgencyId_;
    _defaultAgencyVeriSign = defaultAgencyVeriSign_;
    emit EvtSetDefaultAgencyInfo(defaultAgencyId_, defaultAgencyVeriSign_);
  }

  function setAgencyMaxAllowableMintedTokens(
    string memory agencyId_,
    uint256 agencyMaxAllowableMintedTokens_
  ) external isAuthorized {
    _agencyId_maxAllowableMintedTokens[
      agencyId_
    ] = agencyMaxAllowableMintedTokens_;

    emit EvtSetAgencyMaxAllowableMintedTokens(
      agencyId_,
      agencyMaxAllowableMintedTokens_
    );
  }

  function setMetadataTypeStatus(string memory metadataType_, bool allowed_)
    external
    isAuthorized
  {
    _metadataTypeStatusList[metadataType_] = allowed_;

    emit EvtSetMetadataTypeStatus(metadataType_, allowed_);
  }

  // To re-register, first call the function removeAgencyInfo() and then can register again
  function registerAgencyInfo(
    string memory agencyId_,
    string memory agencyVeriSign_
  ) external isAuthorized {
    require(
      bytes(_agencyId_agencyVeriSign[agencyId_]).length == 0,
      "Agency ID already registered"
    );

    _agencyId_agencyVeriSign[agencyId_] = agencyVeriSign_;
    _agencyCount++;
    _agencyIdList.push(bytes32(abi.encodePacked(agencyId_)));

    emit EvtRegisterAgencyInfo(agencyId_, agencyVeriSign_);
  }

  function updateAgencyVeriSign(
    string memory agencyId_,
    string memory agencyVeriSign_
  ) external isAuthorized {
    require(
      bytes(_agencyId_agencyVeriSign[agencyId_]).length > 0,
      "agencyId_ not yet registered"
    );

    _agencyId_agencyVeriSign[agencyId_] = agencyVeriSign_;
    emit EvtUpdateAgencyInfo(agencyId_, agencyVeriSign_);
  }

  function removeAgencyInfo(string memory agencyId_) external isAuthorized {
    require(agencyExists(agencyId_), "agencyId_ not exist");
    delete _agencyId_agencyVeriSign[agencyId_];
    _agencyCount--;

    // Remove agencyId_ from _agencyIdList
    uint256 _agencyIdLength = _agencyIdList.length;
    bytes32 _lastAgencyId;
    for (uint256 i = 0; i < _agencyIdLength; i++) {
      if (_agencyIdList[i] == bytes32(abi.encodePacked(agencyId_))) {
        _lastAgencyId = _agencyIdList[_agencyIdLength - 1];
        _agencyIdList[i] = _lastAgencyId;
        _agencyIdList.pop();
      }
    }

    emit EvtRemoveAgencyInfo(agencyId_);
  }

  function agencyExists(string memory agencyId_) public view returns (bool) {
    return bytes(_agencyId_agencyVeriSign[agencyId_]).length > 0;
  }

  // For Passport
  function setAgencyMetadata(
    string memory agencyId_,
    string memory name_,
    string memory description_,
    string memory animation_url_, // can be empty string if the agency does not wanna specify the default animation
    string memory image_url_ // can be empty string if the agency does not wanna specify the default image
  ) external isAuthorized {
    require(agencyExists(agencyId_), "Agency not exist");

    require(bytes(name_).length > 0, "Invalid name_");
    require(bytes(description_).length > 0, "Invalid description_");

    _agencyId_agencyMetadata[agencyId_] = AgencyMetadata(
      name_,
      description_,
      animation_url_,
      image_url_
    );

    emit EvtSetAgencyMetadata(
      agencyId_,
      name_,
      description_,
      animation_url_,
      image_url_
    );
  }

  // For Stamp
  function setAgencyMultiMetadata(
    string memory agencyId_,
    string memory metadataType_, // "default", "hotel", "flight", "activity"
    string memory name_,
    string memory description_,
    string memory animation_url_, // can be empty string if the agency does not wanna specify the default animation
    string memory image_url_ // can be empty string if the agency does not wanna specify the default image
  ) external isAuthorized {
    require(agencyExists(agencyId_), "Agency not exist");

    require(
      _metadataTypeStatusList[metadataType_] == true,
      "Unsupported metadataType_"
    );

    require(bytes(name_).length > 0, "Invalid name_");
    require(bytes(description_).length > 0, "Invalid description_");

    _agencyId_agencyMultiMetadata[agencyId_][metadataType_] = AgencyMetadata(
      name_,
      description_,
      animation_url_,
      image_url_
    );

    emit EvtSetAgencyMultiMetadata(
      agencyId_,
      metadataType_,
      name_,
      description_,
      animation_url_,
      image_url_
    );
  }

  function addAgencyMetadataAttribute(
    string memory agencyId_,
    string memory trait_type,
    string memory value
  ) external isAuthorized {
    require(
      bytes(_agencyId_agencyMetadata[agencyId_].name).length > 0,
      "Agency metadata not exist"
    );

    require(bytes(trait_type).length > 0, "Invalid trait_type");

    uint256 metadataAttributesLength = _agencyId_agencyMetadataAttributes[
      agencyId_
    ].length;

    for (uint256 i = 0; i < metadataAttributesLength; i++) {
      string memory trait_type_stored = _agencyId_agencyMetadataAttributes[
        agencyId_
      ][i].trait_type;
      if (
        (keccak256(abi.encodePacked((trait_type_stored))) ==
          keccak256(abi.encodePacked((trait_type))))
      ) {
        revert("trait_type already added");
      }
    }

    _agencyId_agencyMetadataAttributes[agencyId_].push(
      AgencyMetadataAttributes(trait_type, value)
    );

    emit EvtAddAgencyMetadataAttribute(agencyId_, trait_type, value);
  }

  // Update "trait_type" with new "value"
  // Set "value" to empty string to wipe the "trait_type"
  function updateAgencyMetadataAttribute(
    string memory agencyId_,
    string memory trait_type,
    string memory value
  ) external isAuthorized {
    require(
      bytes(_agencyId_agencyMetadata[agencyId_].name).length > 0,
      "Agency metadata not exist"
    );

    uint256 metadataAttributesLength = _agencyId_agencyMetadataAttributes[
      agencyId_
    ].length;

    for (uint256 i = 0; i < metadataAttributesLength; i++) {
      string memory trait_type_stored = _agencyId_agencyMetadataAttributes[
        agencyId_
      ][i].trait_type;
      if (
        (keccak256(abi.encodePacked((trait_type_stored))) ==
          keccak256(abi.encodePacked((trait_type))))
      ) {
        _agencyId_agencyMetadataAttributes[agencyId_][i].value = value;
      }
    }

    emit EvtUpdateAgencyMetadataAttribute(agencyId_, trait_type, value);
  }

  function safeGetAgencyId(string memory agencyId_)
    public
    view
    returns (string memory)
  {
    return bytes(agencyId_).length > 0 ? agencyId_ : _defaultAgencyId;
  }

  function safeGetAgencyVeriSign(string memory agencyId_)
    public
    view
    returns (string memory)
  {
    return
      bytes(agencyId_).length > 0
        ? _agencyId_agencyVeriSign[agencyId_]
        : _defaultAgencyVeriSign;
  }

  // Can only be called by the owner contract (Passport or Stamp) whenever token is minted.
  // veriSign will be set if "agencyId_" not empty
  function setTokenIdAgencyInfo(uint256 tokenId_, string memory agencyId_)
    external
  {
    require(msg.sender == _agencyOwnerContractAddress, "Not owner contract");

    uint256 agencyMaxAllowableMintedTokens = _agencyId_maxAllowableMintedTokens[
      agencyId_
    ];
    if (agencyMaxAllowableMintedTokens > 0) {
      require(
        _agencyId_tokenIdList[agencyId_].length <
          agencyMaxAllowableMintedTokens,
        "Agency max allowable minted tokens exceeded"
      );
    } else {
      require(
        _agencyId_tokenIdList[agencyId_].length < _maxMintedTokensPerAgency,
        "Agency max allowable minted tokens exceeded"
      );
    }

    if (
      bytes(agencyId_).length > 0 &&
      keccak256(abi.encodePacked(agencyId_)) !=
      keccak256(abi.encodePacked(_defaultAgencyId))
    ) {
      require(
        bytes(_agencyId_agencyVeriSign[agencyId_]).length > 0,
        "agencyId not registered"
      );

      _tokenId_agencyInfo[tokenId_] = AgencyInfo(
        agencyId_,
        _agencyId_agencyVeriSign[agencyId_],
        block.timestamp
      );

      _agencyId_tokenIdList[agencyId_].push(tokenId_);
    } else {
      _tokenId_agencyInfo[tokenId_] = AgencyInfo(
        _defaultAgencyId,
        "",
        block.timestamp
      );

      _agencyId_tokenIdList[_defaultAgencyId].push(tokenId_);
    }
  }

  // "agencyId_" can be empty str
  // "veriSign" will also be set (no longer empty)
  function updateOrVerifyTokenIdAgencyInfo(
    uint256 tokenId_,
    string memory agencyId_
  ) external isAuthorized {
    _tokenId_agencyInfo[tokenId_] = AgencyInfo(
      safeGetAgencyId(agencyId_),
      safeGetAgencyVeriSign(agencyId_),
      block.timestamp
    );

    emit EvtUpdateOrVerifyTokenIdAgencyInfo(tokenId_, agencyId_);
  }

  function updateOrVerifyManyTokenIdsAgencyInfo(
    uint256[] memory tokenIdList_,
    string memory agencyId_
  ) external isAuthorized {
    for (uint256 i = 0; i < tokenIdList_.length; i++) {
      _tokenId_agencyInfo[tokenIdList_[i]] = AgencyInfo(
        safeGetAgencyId(agencyId_),
        safeGetAgencyVeriSign(agencyId_),
        block.timestamp
      );
    }

    emit EvtUpdateOrVerifyManyTokenIdsAgencyInfo(tokenIdList_, agencyId_);
  }

  function getAgencyTokenIdList(string memory agencyId_)
    external
    view
    returns (uint256[] memory)
  {
    return _agencyId_tokenIdList[agencyId_];
  }

  function getAgencyIdList() external view returns (bytes32[] memory) {
    return _agencyIdList;
  }

  function getAgencyMetadataAttributes(string memory agencyId_)
    external
    view
    returns (AgencyMetadataAttributes[] memory)
  {
    return _agencyId_agencyMetadataAttributes[agencyId_];
  }
}