// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IEquityBadge } from "../../interfaces/IEquityBadge.sol";

/**************************************

    AppStorage library

    ------------------------------

    A specialized version of Diamond Storage is AppStorage.
    This pattern is used to more conveniently and easily share state variables between facets.

 **************************************/

/// @notice AppStorage is a special type of diamond storage under slot 0.
/// @dev AppStorage is the only diamond library (with storage) that can be imported in other diamond storages.
/// @dev Used to mainly store addresses of contracts cross referenced across different modules.
library LibAppStorage {
    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev App storage struct. Special type of diamond storage with no storage pointer.
    /// @param usdt USDT token
    /// @param equityBadge Equity badge
    struct AppStorage {
        IERC20 usdt;
        IEquityBadge equityBadge;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning app storage at 0 slot.
    /// @return s AppStorage struct instance at 0 slot
    function appStorage() internal pure returns (AppStorage storage s) {
        // set slot 0 and return
        assembly {
            s.slot := 0
        }

        // explicit return
        return s;
    }

    // -----------------------------------------------------------------------
    //                              Getters
    // -----------------------------------------------------------------------

    /**************************************

        Get USDT

     **************************************/

    /// @dev Get USDT.
    /// @return IERC20 interface of USDT address
    function getUSDT() internal view returns (IERC20) {
        // return
        return appStorage().usdt;
    }

    /**************************************

        Get badge

     **************************************/

    /// @dev Get equity badge.
    /// @return Equity badge contract instance
    function getBadge() internal view returns (IEquityBadge) {
        // return
        return appStorage().equityBadge;
    }
}