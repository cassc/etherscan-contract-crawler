// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {Amm, CurveSettings} from "../../libraries/LibMagpieAggregator.sol";
import {LibRouter} from "../LibRouter.sol";

interface IRouter {
    event AddAmm(address indexed sender, uint16 ammId, Amm amm);

    function addAmm(uint16 ammId, Amm calldata amm) external;

    event AddAmms(address indexed sender, uint16[] ammIds, Amm[] amms);

    function addAmms(uint16[] calldata ammIds, Amm[] calldata amms) external;

    event RemoveAmm(address indexed sender, uint16 ammId);

    function removeAmm(uint16 ammId) external;

    event UpdateCurveSettings(address indexed sender, CurveSettings curveSettings);

    function updateCurveSettings(address addressProvider) external;
}