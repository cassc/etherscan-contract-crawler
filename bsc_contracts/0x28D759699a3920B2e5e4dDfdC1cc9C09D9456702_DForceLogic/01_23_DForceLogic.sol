// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "../../../LogicBase.sol";
import "../../../interfaces/IDForce.sol";

contract DForceLogic is LogicBase {
    /*** Override internal function ***/

    function _checkMarkets(address xToken)
        internal
        view
        override
        returns (bool isUsedXToken)
    {
        isUsedXToken = IComptrollerDForce(comptroller).hasiToken(xToken);
    }

    function _enterMarkets(address[] calldata xTokens)
        internal
        override
        returns (uint256[] memory)
    {
        bool[] memory results = IComptrollerDForce(comptroller).enterMarkets(
            xTokens
        );

        uint256[] memory resultsUint = new uint256[](results.length);

        for (uint256 i = 0; i < results.length; ) {
            resultsUint[i] = results[i] ? 0 : 1;
            unchecked {
                ++i;
            }
        }

        return resultsUint;
    }

    function _mint(address xToken, uint256 mintAmount)
        internal
        override
        returns (uint256)
    {
        if (xToken == xBNB) {
            IiTokenETH(xToken).mint{value: mintAmount}(address(this));
            return 0;
        }

        IiToken(xToken).mint(address(this), mintAmount);
        return 0;
    }

    function _borrow(address xToken, uint256 borrowAmount)
        internal
        override
        returns (uint256)
    {
        // Get my account's total liquidity value in Compound
        (uint256 liquidity, uint256 shortfall, , ) = IComptrollerDForce(
            comptroller
        ).calcAccountEquity(address(this));

        require(liquidity > 0, "E12");
        require(shortfall == 0, "E11");

        IiToken(xToken).borrow(borrowAmount);
        return 0;
    }

    function _repayBorrow(address xToken, uint256 repayAmount)
        internal
        override
        returns (uint256)
    {
        if (xToken == xBNB) {
            IiTokenETH(xToken).repayBorrow{value: repayAmount}();
            return 0;
        }

        IiToken(xToken).repayBorrow(repayAmount);
        return 0;
    }

    function _redeemUnderlying(address xToken, uint256 redeemAmount)
        internal
        override
        returns (uint256)
    {
        IiToken(xToken).redeemUnderlying(address(this), redeemAmount);
        return 0;
    }

    function _redeem(address xToken, uint256 redeemTokenAmount)
        internal
        override
        returns (uint256)
    {
        IiToken(xToken).redeem(address(this), redeemTokenAmount);
        return 0;
    }

    function _claim(address[] memory xTokens) internal override {
        address[] memory holders = new address[](1);
        holders[0] = address(this);

        IDistributionDForce(rainMaker).claimReward(holders, xTokens);
    }

    function _getAllMarkets()
        internal
        view
        override
        returns (address[] memory)
    {
        return IComptrollerDForce(comptroller).getAlliTokens();
    }
}