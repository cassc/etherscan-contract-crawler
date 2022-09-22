// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICollectionswap is IERC721, IERC721Enumerable {
    struct LPTokenParams721ETH {
        address nftAddress;
        address bondingCurveAddress;
        address payable poolAddress;
        uint96 fee;
        uint128 delta;
        uint128 initialSpotPrice;
        uint256 initialPoolBalance;
        uint256 initialNFTIDsLength;
    }

    function viewPoolParams(uint256 tokenId)
        external
        view
        returns (LPTokenParams721ETH memory poolParams);

    function validatePoolParamsLte(
        uint256 tokenId,
        address nftAddress,
        address bondingCurveAddress,
        uint96 fee,
        uint128 delta
    )
        external
        view
        returns (bool);

    function validatePoolParamsEq(
        uint256 tokenId,
        address nftAddress,
        address bondingCurveAddress,
        uint96 fee,
        uint128 delta
    )
        external
        view
        returns (bool);
}