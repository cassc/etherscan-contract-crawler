// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import {Rescuable} from "../utils/Rescuable.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721, ERC721TokenReceiver} from "@solmate/tokens/ERC721.sol";
import {ERC1155TokenReceiver} from "@solmate/tokens/ERC1155.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {TokenIdentifierLibrary, TokenIdentifier} from "./lib/TokenIdentifier.sol";
import {CrossPostAccount} from "./CrossPostAccount.sol";
import {IOmniAccount} from "./interfaces/IOmniAccount.sol";
import {TokenDelegate} from "./TokenDelegate.sol";

contract OmniAccount is IOmniAccount, CrossPostAccount, Rescuable, ERC721TokenReceiver, ERC1155TokenReceiver {
  TokenDelegate immutable tokenDelegate;

  // Maps TokenIdentifierHash to owner address for recieved nfts
  mapping(bytes32 => address) public owners;

  constructor(address oracleSigner, TokenDelegate tokenDelegate_) {
    setOmniOracleSigner(oracleSigner);
    tokenDelegate = tokenDelegate_;
    emit AccountCreated(address(this), msg.sender);
  }

  function createOrder(TokenIdentifier[] calldata tokens) external {
    for (uint256 i; i < tokens.length; ) {
      TokenIdentifier calldata token = tokens[i];

      IERC721 collection = IERC721(token.collection);

      tokenDelegate.spendFrom(collection, msg.sender, address(this), token.id);

      owners[TokenIdentifierLibrary.hash(token)] = msg.sender;

      unchecked {
        ++i;
      }
    }

    emit OrdersCreated(address(this), msg.sender, tokens);
  }

  function withdraw(TokenIdentifier[] calldata tokens) external {
    for (uint256 i; i < tokens.length; ) {
      if (owners[TokenIdentifierLibrary.hash(tokens[i])] != msg.sender) {
        revert Unauthorized();
      }

      ERC721 collection = ERC721(tokens[i].collection);
      collection.safeTransferFrom(address(this), msg.sender, tokens[i].id);
      delete owners[TokenIdentifierLibrary.hash(tokens[i])];

      unchecked {
        ++i;
      }
    }

    emit OrdersWithdrawn(address(this), msg.sender, tokens);
  }

  function setOwnersForItems(TokenIdentifier[] calldata tokens, address[] calldata ownerArray) external onlyOwner {
    if (tokens.length != ownerArray.length) {
      revert MismatchedInputLength();
    }

    for (uint256 i; i < tokens.length; ) {
      if (owners[TokenIdentifierLibrary.hash(tokens[i])] != address(0)) {
        revert Unauthorized();
      }

      ERC721 collection = ERC721(tokens[i].collection);

      if (collection.ownerOf(tokens[i].id) != address(this)) {
        revert InvalidOrder();
      }

      owners[TokenIdentifierLibrary.hash(tokens[i])] = ownerArray[i];
      unchecked {
        ++i;
      }
    }
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external virtual override returns (bytes4) {
    ERC721 collection = ERC721(msg.sender);
    if (collection.supportsInterface(type(IERC721).interfaceId)) {
      owners[TokenIdentifierLibrary.hash(TokenIdentifier({collection: address(collection), id: tokenId}))] = from;
    }
    return ERC721TokenReceiver.onERC721Received.selector;
  }

  function setPause(bool shouldPause) external onlyOwner {
    if (shouldPause) {
      _pause();
    } else {
      _unpause();
    }
  }

  function withdrawERC721(ERC721 token, uint256[] calldata ids, address recipient) external override onlyOwner {
    for (uint256 i; i < ids.length; ) {
      delete owners[TokenIdentifierLibrary.hash(TokenIdentifier({collection: address(token), id: ids[i]}))];

      token.safeTransferFrom(address(this), recipient, ids[i]);
      unchecked {
        ++i;
      }
    }
  }

  receive() external payable {}

  fallback() external payable {}
}