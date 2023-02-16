// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;


import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721, ERC721TokenReceiver} from "@solmate/tokens/ERC721.sol";
import {ERC1155, ERC1155TokenReceiver} from "@solmate/tokens/ERC1155.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {Rescuable} from "./utils/Rescuable.sol";
import {CrossPostAccount} from "./CrossPostAccount.sol";
import {IOmniAccount} from "./interfaces/IOmniAccount.sol";
import {TokenDelegate} from "./TokenDelegate.sol";

/// A PersonalOmniAccount is a contract that can hold ETH, ERC20, ERC721, and ERC1155 tokens.
/// It assumes that all assets are owned by the owner of the contract.
contract PersonalOmniAccount is IOmniAccount, Rescuable, CrossPostAccount, ERC721TokenReceiver, ERC1155TokenReceiver {
  TokenDelegate public tokenDelegate;

  constructor(address oracleSigner, TokenDelegate tokenDelegate_) {
    setOmniOracleSigner(oracleSigner);
    tokenDelegate = tokenDelegate_;
    emit AccountCreated(address(this), msg.sender);
  }

  function depositETH() external payable {
    emit ETHDeposited(address(this), msg.sender, msg.value);
  }

  function depositERC20(IERC20[] calldata tokens, uint256[] calldata amounts) external {
    if (tokens.length != amounts.length) {
      revert MismatchedInputLength();
    }

    for (uint256 i; i < tokens.length; ) {
      tokenDelegate.transferERC20(tokens[i], msg.sender, address(this), amounts[i]);

      unchecked {
        ++i;
      }
    }
    emit ERC20Deposited(address(this), msg.sender, tokens, amounts);
  }

  function depositERC721(TokenIdentifier[] calldata tokens) external {
    for (uint256 i; i < tokens.length; ) {
      TokenIdentifier calldata token = tokens[i];

      IERC721 collection = IERC721(token.collection);
      tokenDelegate.transferERC721(collection, msg.sender, address(this), token.id);

      unchecked {
        ++i;
      }
    }

    emit ERC721Deposited(address(this), msg.sender, tokens);
  }

  function depositERC1155(TokenIdentifier[] calldata tokens, uint256[] calldata amounts) external {
    if (tokens.length != amounts.length) {
      revert MismatchedInputLength();
    }

    for (uint256 i; i < tokens.length; ) {
      TokenIdentifier calldata token = tokens[i];

      IERC1155 collection = IERC1155(token.collection);
      tokenDelegate.transferERC1155(collection, msg.sender, address(this), token.id, amounts[i]);

      unchecked {
        ++i;
      }
    }

    emit ERC1155Deposited(address(this), msg.sender, tokens, amounts);
  }

  function withdrawETH(uint256 amount) external onlyOwner {
    if (address(this).balance < amount) {
      revert InsufficientBalances();
    }

    payable(msg.sender).transfer(amount);

    emit ETHWithdrawn(address(this), msg.sender, amount);
  }

  function withdrawERC20(IERC20[] calldata tokens, uint256[] calldata amounts) external onlyOwner {
    if (tokens.length != amounts.length) {
      revert MismatchedInputLength();
    }

    for (uint256 i; i < tokens.length; ) {
      /// Rely on underlying ERC20 contract to check if user is trying to withdraw more than they have.
      bool success = tokens[i].transfer(msg.sender, amounts[i]);

      if (!success) {
        revert TransferFailed();
      }

      unchecked {
        ++i;
      }
    }

    emit ERC20Withdrawn(address(this), msg.sender, tokens, amounts);
  }
  
  function withdrawERC721(TokenIdentifier[] calldata tokens) external onlyOwner {
    for (uint256 i; i < tokens.length; ) {
      ERC721 collection = ERC721(tokens[i].collection);
      collection.safeTransferFrom(address(this), msg.sender, tokens[i].id);

      unchecked {
        ++i;
      }
    }

    emit ERC721Withdrawn(address(this), msg.sender, tokens);
  }

  function withdrawERC1155(TokenIdentifier[] calldata tokens, uint256[] calldata amounts) external onlyOwner {
    if (tokens.length != amounts.length) {
      revert MismatchedInputLength();
    }

    for (uint256 i; i < tokens.length; ) {
      ERC1155 collection = ERC1155(tokens[i].collection);
      collection.safeTransferFrom(address(this), msg.sender, tokens[i].id, amounts[i], "");
  
      unchecked {
        ++i;
      }
    }

    emit ERC1155Withdrawn(address(this), msg.sender, tokens, amounts);
  }

  /// @notice Pause or unpause the contract.
  /// @param shouldPause whether to pause or unpause the contract
  function setPause(bool shouldPause) external onlyOwner {
    shouldPause ? _pause() : _unpause();
  }

  /// @notice Set the token delegate.
  /// @param newTokenDelegate the new token delegate
  function setTokenDelegate(address newTokenDelegate) external onlyOwner {
    tokenDelegate = TokenDelegate(newTokenDelegate);
  }

  receive() external payable {}

  fallback() external payable {}
}