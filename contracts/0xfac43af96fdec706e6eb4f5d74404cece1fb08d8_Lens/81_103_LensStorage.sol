// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "../interfaces/aave/IPriceOracleGetter.sol";
import "../interfaces/aave/ILendingPool.sol";
import "../interfaces/aave/IAToken.sol";
import "../interfaces/IMorpho.sol";

import "../libraries/aave/ReserveConfiguration.sol";
import "lib/morpho-utils/src/math/PercentageMath.sol";
import "lib/morpho-utils/src/math/WadRayMath.sol";
import "lib/morpho-utils/src/math/Math.sol";
import "../libraries/aave/DataTypes.sol";
import "../libraries/InterestRatesModel.sol";

/// @title LensStorage.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Base layer to the Morpho Protocol Lens, managing the upgradeable storage layout.
abstract contract LensStorage {
    /// STORAGE ///

    uint16 public constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 5_000; // 50% in basis points.
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18; // Health factor below which the positions can be liquidated.

    IMorpho public immutable morpho;
    ILendingPoolAddressesProvider public immutable addressesProvider;
    ILendingPool public immutable pool;

    /// CONSTRUCTOR ///

    /// @notice Constructs the contract.
    /// @param _morpho The address of the main Morpho contract.
    constructor(address _morpho) {
        morpho = IMorpho(_morpho);
        pool = ILendingPool(morpho.pool());
        addressesProvider = ILendingPoolAddressesProvider(morpho.addressesProvider());
    }
}