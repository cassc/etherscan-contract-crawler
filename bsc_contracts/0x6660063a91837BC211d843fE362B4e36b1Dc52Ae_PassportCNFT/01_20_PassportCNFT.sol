// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../common/TopDownERC721Composable.sol";
import "../common/AgencyNFT.sol";

contract PassportCNFT is AgencyNFT, TopDownERC721Composable {
  constructor(string memory name_, string memory symbol_)
    AgencyNFT(name_, symbol_)
  {}

  // Compose an NFT token into the parent token
  function adminComposeNFT(
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_,
    bool decomposable_
  ) external isAuthorized nonReentrant {
    require(tokenExists(parentTokenId_), "parentTokenId not exist");
    require(_allowedComposedNftList[composedNft_], "Not allowed composedNft");

    address composedTokenIdOwner = IERC721(composedNft_).ownerOf(
      composedTokenId_
    );

    _compose(parentTokenId_, composedNft_, composedTokenId_, decomposable_);

    // Enforce to transfer the composed token
    if (composedTokenIdOwner != address(this)) {
      IERC721(composedNft_).safeTransferFrom(
        composedTokenIdOwner,
        address(this),
        composedTokenId_
      );
    }

    emit EvtComposeNFT(
      _msgSender(),
      parentTokenId_,
      composedNft_,
      composedTokenId_,
      true,
      decomposable_
    );
  }

  // Compose many NFT tokens into the parent token
  function adminComposeNFTMany(
    uint256 parentTokenId_,
    address composedNft_,
    uint256[] memory composedTokenIdList_,
    bool[] memory decomposableList_
  ) external isAuthorized nonReentrant {
    require(tokenExists(parentTokenId_), "parentTokenId not exist");
    require(_allowedComposedNftList[composedNft_], "Not allowed composedNft");
    require(
      composedTokenIdList_.length == decomposableList_.length,
      "Length mismatch"
    );

    for (uint256 i = 0; i < composedTokenIdList_.length; i++) {
      address composedTokenIdOwner = IERC721(composedNft_).ownerOf(
        composedTokenIdList_[i]
      );

      _compose(
        parentTokenId_,
        composedNft_,
        composedTokenIdList_[i],
        decomposableList_[i]
      );

      // Enforce to transfer the composed token
      if (composedTokenIdOwner != address(this)) {
        IERC721(composedNft_).safeTransferFrom(
          composedTokenIdOwner,
          address(this),
          composedTokenIdList_[i]
        );
      }
    }

    emit EvtAdminComposeNFTMany(
      parentTokenId_,
      composedNft_,
      composedTokenIdList_,
      decomposableList_
    );
  }

  // Decompose an NFT token from the parent token
  // Caller must be authorized
  function adminDecomposeNFT(
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_
  ) external isAuthorized nonReentrant {
    require(tokenExists(parentTokenId_), "parentTokenId not exist");
    require(_allowedComposedNftList[composedNft_], "Not allowed composedNft");

    _decompose(parentTokenId_, composedNft_, composedTokenId_);

    emit EvtDecomposeNFT(
      _msgSender(),
      parentTokenId_,
      composedNft_,
      composedTokenId_,
      true
    );
  }

  // Decompose many NFT tokens from the parent token
  function adminDecomposeNFTMany(
    uint256 parentTokenId_,
    address composedNft_,
    uint256[] memory composedTokenIdList_
  ) external isAuthorized nonReentrant {
    require(tokenExists(parentTokenId_), "parentTokenId not exist");
    require(_allowedComposedNftList[composedNft_], "Not allowed composedNft");

    for (uint256 i = 0; i < composedTokenIdList_.length; i++) {
      _decompose(parentTokenId_, composedNft_, composedTokenIdList_[i]);
    }

    emit EvtAdminDecomposeNFTMany(
      parentTokenId_,
      composedNft_,
      composedTokenIdList_
    );
  }
}