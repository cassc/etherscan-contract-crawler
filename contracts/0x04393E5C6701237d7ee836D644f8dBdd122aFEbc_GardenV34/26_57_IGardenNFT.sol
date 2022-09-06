// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IGarden} from './IGarden.sol';
import {IBabController} from './IBabController.sol';

/**
 * @title IGardenNFT
 * @author Babylon Finance
 *
 * Interface for operating with a Garden NFT.
 */
interface IGardenNFT {
    function grantGardenNFT(address _user) external returns (uint256);

    function saveGardenURIAndSeed(
        address _garden,
        string memory _gardenTokenURI,
        uint256 _seed
    ) external;

    function gardenTokenURIs(address _garden) external view returns (string memory);

    function gardenSeeds(address _garden) external view returns (uint256);
}