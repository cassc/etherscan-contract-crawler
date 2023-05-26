// SPDX-License-Identifier: MIT

/**
 * This is a part of an effort to update ERC271 so that the sales transaction
 * becomes decentralized and trustless, which makes it possible to enforce
 * royalities without relying on marketplaces.
 *
 * Please see "https://hackmd.io/@snakajima/BJqG3fkSo" for details.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IERC721Marketplace {
  // Make an offer to a specific token
  function makeAnOffer(IERC721P2PCore _contract, uint256 _tokenId, uint256 _price) external payable;

  // Withdraw an offer to a specific token (onlyOfferMaker)
  function withdrawAnOffer(IERC721P2PCore _contract, uint256 _tokenId) external;

  // Get the current offer to the specifiedToken
  function getTheBestOffer(IERC721P2PCore _contract, uint256 _tokenId) external view returns (uint256, address);

  // It will call the purchase method of _contract with the specified amount of payment.
  function acceptOffer(IERC721P2PCore _contract, uint256 _tokenId, uint256 _price) external;
}

interface IERC721P2PCore {
  // Set the price of the specified token (onlyTokenOwner)
  function setPriceOf(uint256 _tokenId, uint256 _price) external;

  // Get the current price of the specified token
  function getPriceOf(uint256 _tokenId) external view returns (uint256);

  // It will transfer the token and distribute the money, including royalties
  function purchase(uint256 _tokenId, address _buyer, address _facilitator) external payable;

  // It sets the price and calls the acceptOffer method of _dealer (onlyTokenOwner)
  function acceptOffer(uint256 _tokenId, IERC721Marketplace _dealer, uint256 _price) external;
}

// deprecated
interface IERC721P2P is IERC721P2PCore, IERC721 {

}