/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {AddressArrayUtils} from "../../../lib/AddressArrayUtils.sol";
import {IController} from "../../../interfaces/IController.sol";
import {IStaticOracle} from "../../../interfaces/external/IStaticOracle.sol";
import {IPriceOracle} from "../../../interfaces/IPriceOracle.sol";
import {IUniswapV2Pair} from "../../../interfaces/external/IUniswapV2Pair.sol";
import {UniswapV2Library} from "../../../../external/contracts/uniswap/v2/lib/UniswapV2Library.sol";
import {PreciseUnitMath} from "../../../lib/PreciseUnitMath.sol";
import {ResourceIdentifier} from "../../lib/ResourceIdentifier.sol";

contract UniswapV3TWAPOracleAdapter is Ownable {
    using AddressArrayUtils for address[];
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;

    /* ============ State Variables ============ */

    // Instance of the Controller contract
    IController public controller;

    // Address of Uniswap factory
    IStaticOracle public staticOracle;

    /* ============ Constructor ============ */

    /**
     * Set state variables
     *
     * @param _controller         Instance of controller contract
     * @param _staticOracle     Address of Uniswap Oracle 
     
     */
    constructor(IController _controller, IStaticOracle _staticOracle) public {
        controller = _controller;
        staticOracle = _staticOracle;
    }

    /* ============ External Functions ============ */

    /**
     * Calculate price from Uniswap. Note: must be system contract to be able to retrieve price. If both assets are
     * not Uniswap pool, return false.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     */
    function getPrice(
        address _assetOne,
        address _assetTwo
    ) external view returns (bool, uint256) {
        // require(
        //     controller.isSystemContract(msg.sender),
        //     "Must be system contract"
        // );
        ERC20 token1 = ERC20(_assetOne);
        uint256 decimals = token1.decimals();
        (uint256 price, address[] memory queriedPools) = staticOracle
            .quoteAllAvailablePoolsWithTimePeriod(
                uint128(1 * 10 ** decimals),
                _assetOne,
                _assetTwo,
                3600
            );
        return (true, price);
    }
}