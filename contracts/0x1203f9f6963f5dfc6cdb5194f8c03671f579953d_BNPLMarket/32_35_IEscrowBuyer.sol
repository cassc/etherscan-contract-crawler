// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BasicOrderParameters } from "../seaport/lib/ConsiderationStructs.sol";

import "./IBNPLMarket.sol";

/**
 * @notice It is the interface of functions that we use for the canonical WETH contract.
 *
 * @author [email protected]
 */
interface IEscrowBuyer {
    function initialize() external;

    function fulfillBasicOrderThrough(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool);

    function claimNFT(
        address tokenAddress,
        uint256 tokenId,
        IBNPLMarket.TokenType tokenType,
        uint256 amount,
        address recipient
    ) external returns (bool);

    function hasOwnershipOfAsset(
        address assetContractAddress,
        uint256 assetTokenId,
        uint256 quantity,
        IBNPLMarket.TokenType tokenType
    ) external view returns (bool);
}