// SPDX-License-Identifier: MIT

// Proton.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IUniverse.sol";
import "../interfaces/IChargedState.sol";
import "../interfaces/IChargedSettings.sol";
import "../interfaces/IChargedParticles.sol";

import "../lib/BlackholePrevention.sol";
import "../lib/RelayRecipient.sol";


interface IProton is IERC721 {
  event UniverseSet(address indexed universe);
  event ChargedStateSet(address indexed chargedState);
  event ChargedSettingsSet(address indexed chargedSettings);
  event ChargedParticlesSet(address indexed chargedParticles);
  event PausedStateSet(bool isPaused);
  event SalePriceSet(uint256 indexed tokenId, uint256 salePrice);
  event CreatorRoyaltiesSet(uint256 indexed tokenId, uint256 royaltiesPct);
  event FeesWithdrawn(address indexed receiver, uint256 amount);
  event ProtonSold(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner, uint256 salePrice, address creator, uint256 creatorRoyalties);
  event RoyaltiesClaimed(address indexed receiver, uint256 amountClaimed);

  /***********************************|
  |              Public               |
  |__________________________________*/

  function creatorOf(uint256 tokenId) external view returns (address);
  function getSalePrice(uint256 tokenId) external view returns (uint256);
  function getLastSellPrice(uint256 tokenId) external view returns (uint256);
  function getCreatorRoyalties(address account) external view returns (uint256);
  function getCreatorRoyaltiesPct(uint256 tokenId) external view returns (uint256);
  function getCreatorRoyaltiesReceiver(uint256 tokenId) external view returns (address);

  function buyProton(uint256 tokenId) external payable returns (bool);
  function claimCreatorRoyalties() external returns (uint256);

  function createChargedParticle(
    address creator,
    address receiver,
    address referrer,
    string memory tokenMetaUri,
    string memory walletManagerId,
    address assetToken,
    uint256 assetAmount,
    uint256 annuityPercent
  ) external returns (uint256 newTokenId);

  function createBasicProton(
    address creator,
    address receiver,
    string memory tokenMetaUri
  ) external returns (uint256 newTokenId);

  function createProton(
    address creator,
    address receiver,
    string memory tokenMetaUri,
    uint256 annuityPercent
  ) external returns (uint256 newTokenId);

  function createProtonForSale(
    address creator,
    address receiver,
    string memory tokenMetaUri,
    uint256 annuityPercent,
    uint256 royaltiesPercent,
    uint256 salePrice
  ) external returns (uint256 newTokenId);

  function batchProtonsForSale(
    address creator,
    uint256 annuityPercent,
    uint256 royaltiesPercent,
    string[] calldata tokenMetaUris,
    uint256[] calldata salePrices
  ) external;

  /***********************************|
  |     Only Token Creator/Owner      |
  |__________________________________*/

  function setSalePrice(uint256 tokenId, uint256 salePrice) external;
  function setRoyaltiesPct(uint256 tokenId, uint256 royaltiesPct) external;
  function setCreatorRoyaltiesReceiver(uint256 tokenId, address receiver) external;
}