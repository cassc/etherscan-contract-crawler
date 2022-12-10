// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../interfaces/IPool.sol";
import {PToken} from "./PToken.sol";
import {INTokenApeStaking} from "../../interfaces/INTokenApeStaking.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {XTokenType} from "../../interfaces/IXTokenType.sol";
import {ApeCoinStaking} from "../../dependencies/yoga-labs/ApeCoinStaking.sol";
import {INToken} from "../../interfaces/INToken.sol";
import {IPToken} from "../../interfaces/IPToken.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IScaledBalanceToken} from "../../interfaces/IScaledBalanceToken.sol";
import {IncentivizedERC20} from "./base/IncentivizedERC20.sol";

/**
 * @title sApe PToken
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract PTokenSApe is PToken {
    using WadRayMath for uint256;

    INTokenApeStaking immutable nBAYC;
    INTokenApeStaking immutable nMAYC;

    constructor(
        IPool pool,
        address _nBAYC,
        address _nMAYC
    ) PToken(pool) {
        require(_nBAYC != address(0) && _nMAYC != address(0));
        nBAYC = INTokenApeStaking(_nBAYC);
        nMAYC = INTokenApeStaking(_nMAYC);
    }

    function mint(
        address,
        address,
        uint256,
        uint256
    ) external virtual override onlyPool returns (bool) {
        revert("not allowed");
    }

    function burn(
        address,
        address,
        uint256,
        uint256
    ) external virtual override onlyPool {
        revert("not allowed");
    }

    function balanceOf(address user) public view override returns (uint256) {
        uint256 totalStakedAPE = nBAYC.getUserApeStakingAmount(user) +
            nMAYC.getUserApeStakingAmount(user);
        return totalStakedAPE;
    }

    function scaledBalanceOf(address user)
        public
        view
        override
        returns (uint256)
    {
        return balanceOf(user);
    }

    function transferUnderlyingTo(address, uint256)
        external
        virtual
        override
        onlyPool
    {
        revert("not allowed");
    }

    function transferOnLiquidation(
        address,
        address,
        uint256
    ) external view override onlyPool {
        revert("not allowed");
    }

    function _transfer(
        address,
        address,
        uint128
    ) internal virtual override {
        revert("not allowed");
    }

    function getXTokenType()
        external
        pure
        virtual
        override
        returns (XTokenType)
    {
        return XTokenType.PTokenSApe;
    }
}