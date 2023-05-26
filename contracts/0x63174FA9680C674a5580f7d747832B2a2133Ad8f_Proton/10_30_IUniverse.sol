// SPDX-License-Identifier: MIT

// IUniverse.sol -- Part of the Charged Particles Protocol
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

pragma solidity >=0.6.0;

/**
 * @title Universal Controller interface
 * @dev ...
 */
interface IUniverse {

  event ChargedParticlesSet(address indexed chargedParticles);
  event PhotonSet(address indexed photonToken, uint256 maxSupply);
  event ProtonTokenSet(address indexed protonToken);
  event LeptonTokenSet(address indexed leptonToken);
  event QuarkTokenSet(address indexed quarkToken);
  event BosonTokenSet(address indexed bosonToken);
  event EsaMultiplierSet(address indexed assetToken, uint256 multiplier);
  event ElectrostaticAttraction(address indexed account, address photonSource, uint256 energy, uint256 multiplier);
  event ElectrostaticDischarge(address indexed account, address photonSource, uint256 energy);

  function onEnergize(
    address sender,
    address referrer,
    address contractAddress,
    uint256 tokenId,
    string calldata managerId,
    address assetToken,
    uint256 assetEnergy
  ) external;

  function onDischarge(
    address contractAddress,
    uint256 tokenId,
    string calldata managerId,
    address assetToken,
    uint256 creatorEnergy,
    uint256 receiverEnergy
  ) external;

  function onDischargeForCreator(
    address contractAddress,
    uint256 tokenId,
    string calldata managerId,
    address creator,
    address assetToken,
    uint256 receiverEnergy
  ) external;

  function onRelease(
    address contractAddress,
    uint256 tokenId,
    string calldata managerId,
    address assetToken,
    uint256 principalEnergy,
    uint256 creatorEnergy,
    uint256 receiverEnergy
  ) external;

  function onCovalentBond(
    address contractAddress,
    uint256 tokenId,
    string calldata managerId,
    address nftTokenAddress,
    uint256 nftTokenId
  ) external;

  function onCovalentBreak(
    address contractAddress,
    uint256 tokenId,
    string calldata managerId,
    address nftTokenAddress,
    uint256 nftTokenId
  ) external;

  function onProtonSale(
    address contractAddress,
    uint256 tokenId,
    address oldOwner,
    address newOwner,
    uint256 salePrice,
    address creator,
    uint256 creatorRoyalties
  ) external;
}