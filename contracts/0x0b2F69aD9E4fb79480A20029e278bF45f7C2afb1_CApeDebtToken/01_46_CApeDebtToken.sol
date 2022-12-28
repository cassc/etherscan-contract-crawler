// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../interfaces/IPool.sol";
import {ICApe} from "../../interfaces/ICApe.sol";
import {RebasingDebtToken} from "./RebasingDebtToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";

/**
 * @title stETH Rebasing Debt Token
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract CApeDebtToken is RebasingDebtToken {
    constructor(IPool pool) RebasingDebtToken(pool) {
        //intentionally empty
    }

    /**
     * @return Current rebasing index of PsAPE in RAY
     **/
    function lastRebasingIndex() internal view override returns (uint256) {
        return ICApe(_underlyingAsset).getPooledApeByShares(WadRayMath.RAY);
    }
}