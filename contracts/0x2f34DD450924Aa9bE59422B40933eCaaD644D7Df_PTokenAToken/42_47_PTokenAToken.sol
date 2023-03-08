// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../interfaces/IPool.sol";
import {RebasingPToken} from "./RebasingPToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IAToken} from "../../interfaces/IAToken.sol";
import {XTokenType} from "../../interfaces/IXTokenType.sol";

/**
 * @title aToken Rebasing PToken
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract PTokenAToken is RebasingPToken {
    constructor(IPool pool) RebasingPToken(pool) {
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

    function getXTokenType() external pure override returns (XTokenType) {
        return XTokenType.PTokenAToken;
    }
}