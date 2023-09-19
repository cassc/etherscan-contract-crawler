// SPDX-License-Identifier: MIT

// IChargedSettings.sol -- Part of the Charged Particles Protocol
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

import "./IWalletManager.sol";
import "./IBasketManager.sol";

/**
 * @notice Interface for Charged Wallet-Managers
 */
interface IChargedManagers {

  /***********************************|
  |             Public API            |
  |__________________________________*/

  function isContractOwner(address contractAddress, address account) external view returns (bool);

  // ERC20
  function isWalletManagerEnabled(string calldata walletManagerId) external view returns (bool);
  function getWalletManager(string calldata walletManagerId) external view returns (IWalletManager);

  // ERC721
  function isNftBasketEnabled(string calldata basketId) external view returns (bool);
  function getBasketManager(string calldata basketId) external view returns (IBasketManager);

  // Validation
  function validateDeposit(
    address sender,
    address contractAddress,
    uint256 tokenId,
    string calldata walletManagerId,
    address assetToken,
    uint256 assetAmount
  ) external;
  function validateNftDeposit(
    address sender,
    address contractAddress,
    uint256 tokenId,
    string calldata basketManagerId,
    address nftTokenAddress,
    uint256 nftTokenId,
    uint256 nftTokenAmount
  ) external;
  function validateDischarge(address sender, address contractAddress, uint256 tokenId) external;
  function validateRelease(address sender, address contractAddress, uint256 tokenId) external;
  function validateBreakBond(address sender, address contractAddress, uint256 tokenId) external;

  /***********************************|
  |          Particle Events          |
  |__________________________________*/

  event Initialized(address indexed initiator);
  event ControllerSet(address indexed controllerAddress, string controllerId);
  event WalletManagerRegistered(string indexed walletManagerId, address indexed walletManager);
  event BasketManagerRegistered(string indexed basketId, address indexed basketManager);
}