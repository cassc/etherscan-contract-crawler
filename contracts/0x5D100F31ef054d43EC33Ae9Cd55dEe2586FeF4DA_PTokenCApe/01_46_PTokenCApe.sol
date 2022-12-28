// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../interfaces/IPool.sol";
import {RebasingPToken} from "./RebasingPToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {ICApe} from "../../interfaces/ICApe.sol";
import {XTokenType} from "../../interfaces/IXTokenType.sol";

/**
 * @title aToken Rebasing PToken
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract PTokenCApe is RebasingPToken {
    constructor(IPool pool) RebasingPToken(pool) {
        //intentionally empty
    }

    /**
     * @return Current rebasing index of PsAPE in RAY
     **/
    function lastRebasingIndex() internal view override returns (uint256) {
        return ICApe(_underlyingAsset).getPooledApeByShares(WadRayMath.RAY);
    }

    function getXTokenType() external pure override returns (XTokenType) {
        return XTokenType.PTokenAToken;
    }
}