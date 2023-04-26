// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "../../../LogicBase.sol";
import "../../../interfaces/ICompound.sol";

contract OlaLogic is LogicBase {
    function _checkMarkets(address xToken)
        internal
        view
        override
        returns (bool isUsedXToken)
    {
        (isUsedXToken, , , , , ) = IComptrollerOla(comptroller).markets(xToken);
    }

    function _claim(address[] memory xTokens) internal override {
        IDistributionOla(rainMaker).claimComp(address(this), xTokens);
    }
}