// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../interfaces/IPool.sol";
import {RebasingDebtToken} from "./RebasingDebtToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IAToken} from "../../interfaces/IAToken.sol";

/**
 * @title aToken Rebasing Debt Token
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract ATokenDebtToken is RebasingDebtToken {
    constructor(IPool pool) RebasingDebtToken(pool) {
        //intentionally empty
    }

    /**
     * @return Current rebasing index of aToken in RAY
     **/
    function lastRebasingIndex() internal view override returns (uint256) {
        // Returns Aave aToken liquidity index
        return
            IAToken(_underlyingAsset).POOL().getReserveNormalizedIncome(
                IAToken(_underlyingAsset).UNDERLYING_ASSET_ADDRESS()
            );
    }
}