// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './IFlavorInfo.sol';

/**
 * @title Interface for Providing a FlavorInfo definition.
 * @author @NFTCulture
 */
interface IFlavorInfoProvider is IFlavorInfo {
    function provideFlavorInfos() external view returns (FlavorInfo[] memory);
}