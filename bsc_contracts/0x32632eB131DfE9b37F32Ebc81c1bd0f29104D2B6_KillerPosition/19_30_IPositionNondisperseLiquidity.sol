/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./ILiquidityManager.sol";
import "./ILiquidityManagerNFT.sol";

interface IPositionNondisperseLiquidity is
    ILiquidityManager,
    ILiquidityManagerNFT,
    IERC721Upgradeable
{}