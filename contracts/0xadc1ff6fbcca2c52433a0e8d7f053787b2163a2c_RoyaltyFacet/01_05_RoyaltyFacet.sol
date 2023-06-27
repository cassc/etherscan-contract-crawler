// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { RoyaltyStorage } from "../libraries/RoyaltyStorage.sol";
import { IERC2981 } from "../interfaces/IERC2981.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract RoyaltyFacet is IERC2981 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        RoyaltyStorage.RoyaltyInfo storage ryl = RoyaltyStorage.royaltyInfo();

        // intermediate multiplication overflow is theoretically possible here, but
        // not an issue in practice because of practical constraints of salePrice
        return (ryl.royaltyReceiver, (ryl.defaultRoyaltyBPS * salePrice) / 10000);
    }

    function setRoyalty(uint16 royaltyBPS) external {
        LibDiamond.enforceIsContractOwner();
        RoyaltyStorage.royaltyInfo().defaultRoyaltyBPS = royaltyBPS;
    }
}