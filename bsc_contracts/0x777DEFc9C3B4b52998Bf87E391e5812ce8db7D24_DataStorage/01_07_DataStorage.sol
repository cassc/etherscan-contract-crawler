// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../common/OwnPauseBase.sol";
import "../common/IAgencyNFT.sol";
import "../passport/IPassportCNFT.sol";

contract DataStorage is OwnPauseBase {
  address public _passportContractAddress;

  address public _stampContractAddress;

  string public _delimiter = "===";

  // tokenId => string of private data string (encrypted)
  mapping(uint256 => string) private _passportTokenId_privateData;

  // tokenId => string of public data string
  mapping(uint256 => string) public _passportTokenId_publicData;

  // tokenId => string of private data string (encrypted)
  mapping(uint256 => string) private _stampTokenId_privateData;

  // tokenId => string of public data string
  mapping(uint256 => string) public _stampTokenId_publicData;

  event EvtSetPassportContractAddress(address passportContractAddress);
  event EvtSetStampContractAddress(address stampContractAddress);

  event EvtSetTokenIdPrivateData(uint256 tokenId, bool isForPassport);
  event EvtDeleteTokenIdPrivateData(uint256 tokenId, bool isForPassport);
  event EvtDeleteTokenIdPrivateDataMany(
    uint256[] tokenIdList,
    bool isForPassport
  );

  event EvtSetTokenIdDataVisibility(
    uint256 tokenId,
    bool isPublic,
    bool isForPassport
  );
  event EvtSetTokenIdDataVisibilityMany(
    uint256[] tokenIdList,
    bool isPublic,
    bool isForPassport
  );

  event EvtViewPassportTokenIdPrivateData(uint256 tokenId, string privateData);
  event EvtViewPassportTokenIdPrivateDataMany(
    uint256[] tokenIdList,
    string privateData
  );
  event EvtViewPassportTokenIdPublicDataMany(
    uint256[] tokenIdList,
    string publicData
  );

  event EvtViewStampTokenIdPrivateData(uint256 tokenId, string privateData);
  event EvtViewStampTokenIdPrivateDataMany(
    uint256[] tokenIdList,
    string privateData
  );
  event EvtViewStampTokenIdPublicDataMany(
    uint256[] tokenIdList,
    string publicData
  );

  constructor(address passportContractAddress_, address stampContractAddress_) {
    _passportContractAddress = passportContractAddress_;
    _stampContractAddress = stampContractAddress_;
  }

  function setPassportContractAddress(address passportContractAddress_)
    external
    isOwner
  {
    require(
      passportContractAddress_ != address(0),
      "Invalid passportContractAddress_"
    );
    _passportContractAddress = passportContractAddress_;

    emit EvtSetPassportContractAddress(passportContractAddress_);
  }

  function setStampContractAddress(address stampContractAddress_)
    external
    isOwner
  {
    require(
      stampContractAddress_ != address(0),
      "Invalid stampContractAddress_"
    );
    _stampContractAddress = stampContractAddress_;

    emit EvtSetStampContractAddress(stampContractAddress_);
  }

  function setTokenIdPrivateData(
    uint256 tokenId_,
    string memory privateData_,
    bool isForPassport_
  ) external whenNotPaused isAuthorized {
    if (isForPassport_) {
      require(
        IAgencyNFT(_passportContractAddress).tokenExists(tokenId_),
        "tokenId not exist"
      );
      _passportTokenId_privateData[tokenId_] = privateData_;
    } else {
      require(
        IAgencyNFT(_stampContractAddress).tokenExists(tokenId_),
        "tokenId not exist"
      );
      _stampTokenId_privateData[tokenId_] = privateData_;
    }

    // Do not include the "privateData_" in the emitted Event
    emit EvtSetTokenIdPrivateData(tokenId_, isForPassport_);
  }

  function deleteTokenIdPrivateData(uint256 tokenId_, bool isForPassport_)
    external
    whenNotPaused
    isAuthorized
  {
    if (isForPassport_) {
      // No need to check if token exists
      delete _passportTokenId_privateData[tokenId_];
    } else {
      // No need to check if token exists
      delete _stampTokenId_privateData[tokenId_];
    }

    emit EvtDeleteTokenIdPrivateData(tokenId_, isForPassport_);
  }

  function deleteTokenIdPrivateDataMany(
    uint256[] memory tokenIdList_,
    bool isForPassport_
  ) external whenNotPaused isAuthorized {
    if (isForPassport_) {
      for (uint256 i = 0; i < tokenIdList_.length; i++) {
        // No need to check if token exists
        delete _passportTokenId_privateData[tokenIdList_[i]];
      }
    } else {
      for (uint256 i = 0; i < tokenIdList_.length; i++) {
        // No need to check if token exists
        delete _stampTokenId_privateData[tokenIdList_[i]];
      }
    }

    emit EvtDeleteTokenIdPrivateDataMany(tokenIdList_, isForPassport_);
  }

  function setTokenIdDataVisibility(
    uint256 tokenId_,
    bool isPublic_,
    bool isForPassport_
  ) external whenNotPaused {
    if (isForPassport_) {
      require(
        checkAuthorized(msg.sender) ||
          IAgencyNFT(_passportContractAddress).ownerOf(tokenId_) == msg.sender,
        "not authorized or not token owner"
      );

      // make data public
      if (isPublic_) {
        // Copy from private to public storage
        _passportTokenId_publicData[tokenId_] = _passportTokenId_privateData[
          tokenId_
        ];

        // Delete away the private
        delete _passportTokenId_privateData[tokenId_];
      } else {
        // make data private
        // Copy from public to private storage
        _passportTokenId_privateData[tokenId_] = _passportTokenId_publicData[
          tokenId_
        ];

        // Delete away the public
        delete _passportTokenId_publicData[tokenId_];
      }
    } else {
      // Get the passport tokenId from the stamp tokenId
      uint256 passportTokenId = IPassportCNFT(_passportContractAddress)
        ._composedNFT_parentTokenId(tokenId_, _stampContractAddress);

      require(
        checkAuthorized(msg.sender) ||
          IAgencyNFT(_stampContractAddress).ownerOf(tokenId_) == msg.sender ||
          (passportTokenId > 0 &&
            IAgencyNFT(_passportContractAddress).ownerOf(passportTokenId) ==
            msg.sender),
        "not authorized or not token owner"
      );

      if (isPublic_) {
        // Copy from private to public storage
        _stampTokenId_publicData[tokenId_] = _stampTokenId_privateData[
          tokenId_
        ];

        // Delete away the private
        delete _stampTokenId_privateData[tokenId_];
      } else {
        // make data private
        // Copy from public to private storage
        _stampTokenId_privateData[tokenId_] = _stampTokenId_publicData[
          tokenId_
        ];

        // Delete away the public
        delete _stampTokenId_publicData[tokenId_];
      }
    }

    emit EvtSetTokenIdDataVisibility(tokenId_, isPublic_, isForPassport_);
  }

  function setTokenIdDataVisibilityMany(
    uint256[] memory tokenIdList_,
    bool isPublic_,
    bool isForPassport_
  ) external whenNotPaused isAuthorized {
    if (isForPassport_) {
      // make data public
      if (isPublic_) {
        for (uint256 i = 0; i < tokenIdList_.length; i++) {
          // Copy from private to public storage
          _passportTokenId_publicData[
            tokenIdList_[i]
          ] = _passportTokenId_privateData[tokenIdList_[i]];

          // Delete away the private
          delete _passportTokenId_privateData[tokenIdList_[i]];
        }
      } else {
        // make data private
        for (uint256 i = 0; i < tokenIdList_.length; i++) {
          // Copy from public to private storage
          _passportTokenId_privateData[
            tokenIdList_[i]
          ] = _passportTokenId_publicData[tokenIdList_[i]];

          // Delete away the public
          delete _passportTokenId_publicData[tokenIdList_[i]];
        }
      }
    } else {
      // make data public
      if (isPublic_) {
        for (uint256 i = 0; i < tokenIdList_.length; i++) {
          // Copy from private to public storage
          _stampTokenId_publicData[tokenIdList_[i]] = _stampTokenId_privateData[
            tokenIdList_[i]
          ];

          // Delete away the private
          delete _stampTokenId_privateData[tokenIdList_[i]];
        }
      } else {
        // make data private
        for (uint256 i = 0; i < tokenIdList_.length; i++) {
          // Copy from public to private storage
          _stampTokenId_privateData[tokenIdList_[i]] = _stampTokenId_publicData[
            tokenIdList_[i]
          ];

          // Delete away the public
          delete _stampTokenId_publicData[tokenIdList_[i]];
        }
      }
    }

    emit EvtSetTokenIdDataVisibilityMany(
      tokenIdList_,
      isPublic_,
      isForPassport_
    );
  }

  // Before calling this func, check the public field "_passportTokenId_publicData"
  // Calling this view function results in tx
  function viewPassportTokenIdPrivateData(uint256 passportTokenId_)
    external
    whenNotPaused
  {
    require(
      IAgencyNFT(_passportContractAddress).tokenExists(passportTokenId_),
      "passport token not exist"
    );

    require(
      checkAuthorized(msg.sender) ||
        IAgencyNFT(_passportContractAddress).ownerOf(passportTokenId_) ==
        msg.sender,
      "not authorized or not token owner"
    );

    emit EvtViewPassportTokenIdPrivateData(
      passportTokenId_,
      _passportTokenId_privateData[passportTokenId_]
    );
  }

  // Before calling this func, check the public field "_passportTokenId_publicData"
  // Calling this view function results in tx
  function viewPassportTokenIdPrivateDataMany(
    uint256[] memory passportTokenIdList_
  ) external whenNotPaused {
    string memory privDataList = "";

    for (uint256 i = 0; i < passportTokenIdList_.length; i++) {
      require(
        IAgencyNFT(_passportContractAddress).tokenExists(
          passportTokenIdList_[i]
        ),
        "passport token not exist"
      );

      require(
        checkAuthorized(msg.sender) ||
          IAgencyNFT(_passportContractAddress).ownerOf(
            passportTokenIdList_[i]
          ) ==
          msg.sender,
        "not authorized or not token owner"
      );

      privDataList = string(
        abi.encodePacked(
          privDataList,
          _passportTokenId_privateData[passportTokenIdList_[i]],
          _delimiter
        )
      );
    }

    emit EvtViewPassportTokenIdPrivateDataMany(
      passportTokenIdList_,
      privDataList
    );
  }

  function viewPassportTokenIdPublicDataMany(
    uint256[] memory passportTokenIdList_
  ) external view returns (string memory) {
    string memory pubDataList = "";

    for (uint256 i = 0; i < passportTokenIdList_.length; i++) {
      require(
        IAgencyNFT(_passportContractAddress).tokenExists(
          passportTokenIdList_[i]
        ),
        "passport token not exist"
      );

      pubDataList = string(
        abi.encodePacked(
          pubDataList,
          _passportTokenId_publicData[passportTokenIdList_[i]],
          _delimiter
        )
      );
    }

    return pubDataList;
  }

  // Before calling this func, check the public field "_stampTokenId_publicData"
  // Calling this view function results in tx
  function viewStampTokenIdPrivateData(uint256 stampTokenId_)
    external
    whenNotPaused
  {
    require(
      IAgencyNFT(_stampContractAddress).tokenExists(stampTokenId_),
      "stamp token not exist"
    );

    // Get the passport tokenId from the stamp tokenId
    uint256 passportTokenId = IPassportCNFT(_passportContractAddress)
      ._composedNFT_parentTokenId(stampTokenId_, _stampContractAddress);

    require(
      checkAuthorized(msg.sender) ||
        IAgencyNFT(_stampContractAddress).ownerOf(stampTokenId_) ==
        msg.sender ||
        (passportTokenId > 0 &&
          IAgencyNFT(_passportContractAddress).ownerOf(passportTokenId) ==
          msg.sender),
      "not authorized or not token owner"
    );

    emit EvtViewStampTokenIdPrivateData(
      stampTokenId_,
      _stampTokenId_privateData[stampTokenId_]
    );
  }

  // Before calling this func, check the public field "_stampTokenId_publicData"
  // Calling this view function results in tx
  function viewStampTokenIdPrivateDataMany(uint256[] memory stampTokenIdList_)
    external
    whenNotPaused
  {
    string memory privDataList = "";

    for (uint256 i = 0; i < stampTokenIdList_.length; i++) {
      require(
        IAgencyNFT(_stampContractAddress).tokenExists(stampTokenIdList_[i]),
        "stamp token not exist"
      );

      // Get the passport tokenId from the stamp tokenId
      uint256 passportTokenId = IPassportCNFT(_passportContractAddress)
        ._composedNFT_parentTokenId(
          stampTokenIdList_[i],
          _stampContractAddress
        );

      require(
        checkAuthorized(msg.sender) ||
          IAgencyNFT(_stampContractAddress).ownerOf(stampTokenIdList_[i]) ==
          msg.sender ||
          (passportTokenId > 0 &&
            IAgencyNFT(_passportContractAddress).ownerOf(passportTokenId) ==
            msg.sender),
        "not authorized or not token owner"
      );

      privDataList = string(
        abi.encodePacked(
          privDataList,
          _stampTokenId_privateData[stampTokenIdList_[i]],
          _delimiter
        )
      );
    }

    emit EvtViewStampTokenIdPrivateDataMany(stampTokenIdList_, privDataList);
  }

  function viewStampTokenIdPublicDataMany(uint256[] memory stampTokenIdList_)
    external
    view
    returns (string memory)
  {
    string memory pubDataList = "";

    for (uint256 i = 0; i < stampTokenIdList_.length; i++) {
      require(
        IAgencyNFT(_stampContractAddress).tokenExists(stampTokenIdList_[i]),
        "stamp token not exist"
      );

      pubDataList = string(
        abi.encodePacked(
          pubDataList,
          _stampTokenId_publicData[stampTokenIdList_[i]],
          _delimiter
        )
      );
    }

    return pubDataList;
  }
}