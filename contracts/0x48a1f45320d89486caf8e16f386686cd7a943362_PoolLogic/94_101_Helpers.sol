// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IAtomicCollateralizableERC721} from "../../../interfaces/IAtomicCollateralizableERC721.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";

/**
 * @title Helpers library
 *
 */
library Helpers {
    using WadRayMath for uint256;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    // See `IPool` for descriptions
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

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

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @notice Set user's collateral status for specified asset, if current collateral status is true, skip it.
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param reservesData The state of all the reserves
     * @param token The asset address
     * @param user The user address
     **/
    function setAssetUsedAsCollateral(
        DataTypes.UserConfigurationMap storage userConfig,
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address token,
        address user
    ) internal {
        uint16 reserveId = reservesData[token].id;
        bool currentStatus = userConfig.isUsingAsCollateral(reserveId);
        if (!currentStatus) {
            userConfig.setUsingAsCollateral(reserveId, true);
            emit ReserveUsedAsCollateralEnabled(token, user);
        }
    }
}