// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title UserConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
    uint256 internal constant BORROWING_MASK =
    0x5555555555555555555555555555555555555555555555555555555555555555;

    /**
     * @dev Used to validate if a user has been using the reserve for borrowing or as collateral
   * @param _dataLocal The configuration object data
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
   **/
    function isUsingAsCollateralOrBorrowing(uint256 _dataLocal, uint256 reserveIndex)
    internal
    pure
    returns (bool)
    {
        require(reserveIndex < 128, "UL_INVALID_INDEX");
        return (_dataLocal >> (reserveIndex * 2)) & 3 != 0;
    }

    /**
     * @dev Used to validate if a user has been using the reserve for borrowing
   * @param _dataLocal The configuration object data
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing, false otherwise
   **/
    function isBorrowing(uint256 _dataLocal, uint256 reserveIndex)
    internal
    pure
    returns (bool)
    {
        require(reserveIndex < 128, "UL_INVALID_INDEX");
        return (_dataLocal >> (reserveIndex * 2)) & 1 != 0;
    }

    /**
     * @dev Used to validate if a user has been using the reserve as collateral
   * @param _dataLocal The configuration object data
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve as collateral, false otherwise
   **/
    function isUsingAsCollateral(uint256 _dataLocal, uint256 reserveIndex)
    internal
    pure
    returns (bool)
    {
        require(reserveIndex < 128, "UL_INVALID_INDEX");
        return (_dataLocal >> (reserveIndex * 2 + 1)) & 1 != 0;
    }

    /**
     * @dev Used to validate if a user has been borrowing from any reserve
   * @param _dataLocal The configuration object data
   * @return True if the user has been borrowing any reserve, false otherwise
   **/
    function isBorrowingAny(uint256 _dataLocal) internal pure returns (bool) {
        return _dataLocal & BORROWING_MASK != 0;
    }

    /**
     * @dev Used to validate if a user has not been using any reserve
   * @param _dataLocal The configuration object data
   * @return True if the user has been borrowing any reserve, false otherwise
   **/
    function isEmpty(uint256 _dataLocal) internal pure returns (bool) {
        return _dataLocal == 0;
    }
}