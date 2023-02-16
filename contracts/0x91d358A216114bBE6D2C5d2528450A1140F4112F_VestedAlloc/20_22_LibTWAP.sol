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

// Uniswap
import { OracleLibrary } from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

/**************************************

    TWAP oracle library

**************************************/

library LibTWAP {

    /**************************************

        ** Internal: Check price from TWAP **

        ------------------------------

        @param _amount Amount of THOL
        @return value_ Amount of USDT

     **************************************/

    function tholToUsdt(
        address[2] memory _poolPath,
        address[3] memory _tokenPath,
        uint256 _amount
    ) internal view
    returns (uint256) {

        // const
        address tholWeth_ = _poolPath[0];
        address wethUsdt_ = _poolPath[1];
        address thol_ = _tokenPath[0];
        address weth_ = _tokenPath[1];
        address usdt_ = _tokenPath[2];

        // get tick
        (int24 wethTick_, ) = OracleLibrary.consult(
            tholWeth_,
            4 hours
        );

        // 1 thol -> weth
        uint256 wethOut_ = OracleLibrary.getQuoteAtTick(
            wethTick_,
            uint128(_amount),
            thol_,
            weth_
        );

        // get tick
        (int24 usdtTick_, ) = OracleLibrary.consult(
            wethUsdt_,
            4 hours
        );

        // weth -> usdt
        uint256 usdtOut_ = OracleLibrary.getQuoteAtTick(
            usdtTick_,
            uint128(wethOut_),
            weth_,
            usdt_
        );

        // return
        return usdtOut_;

    }

}