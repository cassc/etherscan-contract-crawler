// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ITreasury } from "../../interfaces/ITreasury.sol";

abstract contract FeeMw {
    /*//////////////////////////////////////////////////////////////
                              STATES
    //////////////////////////////////////////////////////////////*/
    address public immutable TREASURY; // solhint-disable-line

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury) {
        require(treasury != address(0), "ZERO_TREASURY_ADDRESS");
        TREASURY = treasury;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _currencyAllowed(address currency) internal view returns (bool) {
        return ITreasury(TREASURY).isCurrencyAllowed(currency);
    }

    function _treasuryAddress() internal view returns (address) {
        return ITreasury(TREASURY).getTreasuryAddress();
    }

    function _treasuryFee() internal view returns (uint256) {
        return ITreasury(TREASURY).getTreasuryFee();
    }
}