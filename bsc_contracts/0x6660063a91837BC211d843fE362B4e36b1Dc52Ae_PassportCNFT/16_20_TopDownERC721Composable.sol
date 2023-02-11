// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OwnPauseBase.sol";

abstract contract TopDownERC721Composable is
  OwnPauseBase,
  ReentrancyGuard,
  IERC721Receiver
{
  // The composed NFT token info
  struct ComposedNFT {
    address nft;
    uint256[] tokenIdList;
  }

  // Parent tokenId => Composed NFT
  mapping(uint256 => ComposedNFT) public _parentTokenId_composedNFT;

  // Composed NFT tokenId => Composed NFT address => Parent NFT tokenId
  // After being decomposed, it no longer has parentTokenId
  mapping(uint256 => mapping(address => uint256))
    public _composedNFT_parentTokenId;

  // Composed NFT tokenId => Composed NFT address => decomposable
  mapping(uint256 => mapping(address => bool)) public _composedNFT_decomposable;

  mapping(address => bool) public _allowedComposedNftList;

  event EvtComposeNFT(
    address sender_,
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_,
    bool isAdmin_,
    bool decomposable_
  );

  event EvtAdminComposeNFTMany(
    uint256 parentTokenId_,
    address composedNft_,
    uint256[] composedTokenIdList_,
    bool[] decomposableList_
  );

  event EvtDecomposeNFT(
    address sender_,
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_,
    bool isAdmin_
  );

  event EvtAdminDecomposeNFTMany(
    uint256 parentTokenId_,
    address composedNft_,
    uint256[] composedTokenIdList_
  );

  event EvtSetDecomposability(
    address composedNft_,
    uint256 composedTokenId_,
    uint256 parentTokenId_,
    bool decomposable_
  );

  function onERC721Received(
    address operator_,
    address from_,
    uint256 tokenId_,
    bytes calldata data_
  ) external pure override returns (bytes4) {
    // Avoid warning
    operator_;
    from_;
    tokenId_;
    data_;

    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function setAllowedComposedNft(address composedNft_, bool allowed_)
    external
    isOwner
  {
    _allowedComposedNftList[composedNft_] = allowed_;
  }

  function _compose(
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_,
    bool decomposable_
  ) internal {
    // If not exist
    if (_parentTokenId_composedNFT[parentTokenId_].nft == address(0)) {
      ComposedNFT memory cNFT;
      cNFT.nft = composedNft_;
      cNFT.tokenIdList = new uint256[](1);
      cNFT.tokenIdList[0] = composedTokenId_;

      _parentTokenId_composedNFT[parentTokenId_] = cNFT;
    } else {
      // If already exist, append the composedTokenId_
      require(
        _parentTokenId_composedNFT[parentTokenId_].nft == composedNft_,
        "composedNft_ mismatch"
      );
      _parentTokenId_composedNFT[parentTokenId_].tokenIdList.push(
        composedTokenId_
      );
    }

    _composedNFT_parentTokenId[composedTokenId_][composedNft_] = parentTokenId_;

    _composedNFT_decomposable[composedTokenId_][composedNft_] = decomposable_;
  }

  // This will transfer the composedTokenId_ to the owner wallet of the parentTokenId_
  function _decompose(
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_
  ) internal {
    require(
      _parentTokenId_composedNFT[parentTokenId_].nft != address(0),
      "composedNft_ not exists"
    );
    require(
      _parentTokenId_composedNFT[parentTokenId_].nft == composedNft_,
      "composedNft_ mismatch"
    );
    require(
      _composedNFT_parentTokenId[composedTokenId_][composedNft_] ==
        parentTokenId_,
      "parentTokenId_ does not include composedTokenId_"
    );

    bool isDecomposable = _composedNFT_decomposable[composedTokenId_][
      composedNft_
    ];

    address nft = _parentTokenId_composedNFT[parentTokenId_].nft;
    address parentTokenIdOwner = IERC721(address(this)).ownerOf(parentTokenId_);

    // Still leave the decomposed tokenId in "tokenIdList" of _parentTokenId_composedNFT
    // When returning the list of composed tokens, check to filter it out

    delete _composedNFT_parentTokenId[composedTokenId_][composedNft_];

    // If decomposable, transfer the composedTokenId_ to the owner wallet of the parentTokenId_ (i.e. passport holder wallet)
    // Else, transfer to address zero instead of burn as burn is not always available for any NFT collection.
    IERC721(nft).safeTransferFrom(
      address(this),
      isDecomposable ? parentTokenIdOwner : address(0),
      composedTokenId_
    );
  }

  function _preCheckComposeDecompose(
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_,
    address caller_
  ) internal view {
    require(
      caller_ == IERC721(address(this)).ownerOf(parentTokenId_),
      "Not parentTokenId owner"
    );

    require(_allowedComposedNftList[composedNft_], "Not allowed composedNft");

    if (tokenComposed(composedNft_, composedTokenId_)) {
      require(
        address(this) == IERC721(composedNft_).ownerOf(composedTokenId_),
        "Different composedTokenId owner"
      );
    } else {
      require(
        caller_ == IERC721(composedNft_).ownerOf(composedTokenId_),
        "Not composedTokenId owner"
      );
    }
  }

  // Compose an NFT token into the parent token
  // Caller must be owner of both parent token and the composed token
  function composeNFT(
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_,
    bool decomposable_
  ) external whenNotPaused nonReentrant {
    IERC721 composedNftContract = IERC721(composedNft_);

    _preCheckComposeDecompose(
      parentTokenId_,
      composedNft_,
      composedTokenId_,
      _msgSender()
    );

    _compose(parentTokenId_, composedNft_, composedTokenId_, decomposable_);

    // Transfer the composed tokenId to this contract address
    composedNftContract.safeTransferFrom(
      _msgSender(),
      address(this),
      composedTokenId_
    );

    emit EvtComposeNFT(
      _msgSender(),
      parentTokenId_,
      composedNft_,
      composedTokenId_,
      false,
      decomposable_
    );
  }

  // Decompose an NFT token from the parent token
  // Caller must be owner of both parent token and the composed token
  function decomposeNFT(
    uint256 parentTokenId_,
    address composedNft_,
    uint256 composedTokenId_
  ) external whenNotPaused nonReentrant {
    _preCheckComposeDecompose(
      parentTokenId_,
      composedNft_,
      composedTokenId_,
      _msgSender()
    );

    _decompose(parentTokenId_, composedNft_, composedTokenId_);

    emit EvtDecomposeNFT(
      _msgSender(),
      parentTokenId_,
      composedNft_,
      composedTokenId_,
      false
    );
  }

  function tokenComposed(address composedNft_, uint256 composedTokenId_)
    public
    view
    returns (bool)
  {
    return _composedNFT_parentTokenId[composedTokenId_][composedNft_] > 0;
  }

  function getComposedTokenList(uint256 parentTokenId_)
    external
    view
    returns (
      uint256[] memory tokenIdList,
      uint256 tokenIdListLength,
      address composedNft
    )
  {
    uint256[] memory currentComposedTokenIdList = _parentTokenId_composedNFT[
      parentTokenId_
    ].tokenIdList;

    address composedNftAddress = _parentTokenId_composedNFT[parentTokenId_].nft;

    uint256 countDecomposedTokens = 0;
    uint256[] memory returnedComposedTokenIdList = new uint256[](
      currentComposedTokenIdList.length
    );

    uint256 returnedComposedTokenIdListIndex = 0;
    for (uint256 i = 0; i < currentComposedTokenIdList.length; i++) {
      if (!tokenComposed(composedNftAddress, currentComposedTokenIdList[i])) {
        countDecomposedTokens++;
      } else {
        returnedComposedTokenIdList[
          returnedComposedTokenIdListIndex
        ] = currentComposedTokenIdList[i];

        returnedComposedTokenIdListIndex++;
      }
    }

    return (
      returnedComposedTokenIdList,
      currentComposedTokenIdList.length - countDecomposedTokens,
      composedNftAddress
    );
  }

  // Auth wallet or token owner can set
  function setDecomposability(
    address composedNft_,
    uint256 composedTokenId_,
    bool decomposable_
  ) external {
    uint256 parentTokenId = _composedNFT_parentTokenId[composedTokenId_][
      composedNft_
    ];

    require(
      checkAuthorized(_msgSender()) ||
        _msgSender() == IERC721(address(this)).ownerOf(parentTokenId),
      "not authorized or not token owner"
    );

    _composedNFT_decomposable[composedTokenId_][composedNft_] = decomposable_;

    emit EvtSetDecomposability(
      composedNft_,
      composedTokenId_,
      parentTokenId,
      decomposable_
    );
  }
}