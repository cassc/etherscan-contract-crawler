// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";

import "./PosterInternalFacet.sol";

contract PosterHelperFacet is PosterInternalFacet {
    using LibBitmap for LibBitmap.Bitmap;

    function userMintedInExhibition(address user, uint16 exhibitionNumber) external view returns (bool) {
        return s().userToMintedInExhibition[user].get(exhibitionNumber);
    }
}