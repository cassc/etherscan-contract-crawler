// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "../../diamond/LibDiamond.sol";
import {Amm, AppStorage} from "../../libraries/LibMagpieAggregator.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {LibCurve} from "../LibCurve.sol";
import {LibRouter} from "../LibRouter.sol";

contract RouterFacet is IRouter {
    AppStorage internal s;

    function addAmm(uint16 ammId, Amm calldata amm) external override {
        LibDiamond.enforceIsContractOwner();
        LibRouter.addAmm(ammId, amm);
    }

    function removeAmm(uint16 ammId) external override {
        LibDiamond.enforceIsContractOwner();
        LibRouter.removeAmm(ammId);
    }

    function addAmms(uint16[] calldata ammIds, Amm[] calldata amms) external override {
        LibDiamond.enforceIsContractOwner();
        LibRouter.addAmms(ammIds, amms);
    }

    function updateCurveSettings(address addressProvider) external override {
        LibDiamond.enforceIsContractOwner();
        LibCurve.updateSettings(addressProvider);
    }
}