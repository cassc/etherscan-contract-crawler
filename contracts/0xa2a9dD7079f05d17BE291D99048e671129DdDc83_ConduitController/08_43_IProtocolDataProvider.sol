// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

interface IProtocolDataProvider {
    /**
     * @notice Returns the reserve data
     * @param asset The address of the underlying asset of the reserve
     * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
     * @return totalPToken The total supply of the xToken
     * @return totalVariableDebt The total variable debt of the reserve
     * @return liquidityRate The liquidity rate of the reserve
     * @return variableBorrowRate The variable borrow rate of the reserve
     * @return liquidityIndex The liquidity index of the reserve
     * @return variableBorrowIndex The variable borrow index of the reserve
     * @return lastUpdateTimestamp The timestamp of the last update of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 accruedToTreasuryScaled,
            uint256 totalPToken,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    /**
     * @notice Returns the total supply of xTokens for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total supply of the xToken
     **/
    function getXTokenTotalSupply(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the total debt for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total debt for asset
     **/
    function getTotalDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the list of the existing reserves in the pool.
     * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
     * @return The list of reserves, pairs of symbols and addresses
     */
    function getAllReservesTokens()
        external
        view
        returns (DataTypes.TokenData[] memory);

    /**
     * @notice Returns the list of the existing XTokens(PToken+NToken) in the pool.
     * @return The list of XTokens, pairs of symbols and addresses
     */
    function getAllXTokens()
        external
        view
        returns (DataTypes.TokenData[] memory);

    /**
     * @notice Returns the configuration data of the reserve
     * @dev Not returning borrow and supply caps for compatibility, nor pause flag
     * @param asset The address of the underlying asset of the reserve
     **/
    function getReserveConfigurationData(address asset)
        external
        view
        returns (DataTypes.ReserveConfigData memory reserveData);

    /**
     * @notice Returns the caps parameters of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return borrowCap The borrow cap of the reserve
     * @return supplyCap The supply cap of the reserve
     **/
    function getReserveCaps(address asset)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Returns the siloed borrowing flag
     * @param asset The address of the underlying asset of the reserve
     * @return True if the asset is siloed for borrowing
     **/
    function getSiloedBorrowing(address asset) external view returns (bool);

    /**
     * @notice Returns the protocol fee on the liquidation bonus
     * @param asset The address of the underlying asset of the reserve
     * @return The protocol fee on liquidation
     **/
    function getLiquidationProtocolFee(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the user data in a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param user The address of the user
     * @return currentXTokenBalance The current XToken balance of the user
     * @return scaledXTokenBalance The scaled XToken balance of the user
     * @return collateralizedBalance The collateralized balance of the user
     * @return currentVariableDebt The current variable debt of the user
     * @return scaledVariableDebt The scaled variable debt of the user
     * @return liquidityRate The liquidity rate of the reserve
     * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
     *         otherwise
     **/
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentXTokenBalance,
            uint256 scaledXTokenBalance,
            uint256 collateralizedBalance,
            uint256 currentVariableDebt,
            uint256 scaledVariableDebt,
            uint256 liquidityRate,
            bool usageAsCollateralEnabled
        );

    /**
     * @notice Returns the token addresses of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return xTokenAddress The PToken address of the reserve
     * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
     */
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (address xTokenAddress, address variableDebtTokenAddress);

    /**
     * @notice Returns the address of the Interest Rate strategy
     * @param asset The address of the underlying asset of the reserve
     * @return interestRateStrategyAddress The address of the Interest Rate strategy
     * @return auctionStrategyAddress The address of the Auction strategy
     */
    function getStrategyAddresses(address asset)
        external
        view
        returns (
            address interestRateStrategyAddress,
            address auctionStrategyAddress
        );
}