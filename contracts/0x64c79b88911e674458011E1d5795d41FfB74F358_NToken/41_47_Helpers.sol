// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IAtomicCollateralizableERC721} from "../../../interfaces/IAtomicCollateralizableERC721.sol";

/**
 * @title Helpers library
 *
 */
library Helpers {
    using WadRayMath for uint256;

    /**
     * @notice Fetches the user current stable and variable debt balances
     * @param user The user address
     * @param debtTokenAddress The debt token address
     * @return The variable debt balance
     **/
    function getUserCurrentDebt(address user, address debtTokenAddress)
        internal
        view
        returns (uint256)
    {
        return (IERC20(debtTokenAddress).balanceOf(user));
    }

    function getTraitBoostedTokenPrice(
        address xTokenAddress,
        uint256 assetPrice,
        uint256 tokenId
    ) internal view returns (uint256) {
        uint256 multiplier = IAtomicCollateralizableERC721(xTokenAddress)
            .getTraitMultiplier(tokenId);
        return assetPrice.wadMul(multiplier);
    }
}