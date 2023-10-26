// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICouponsForDollarsCalculator.sol";
import "./UbiquityAlgorithmicDollarManager.sol";
import "./libs/ABDKMathQuad.sol";
import "./DebtCoupon.sol";

/// @title Uses the following formula: ((1/(1-R)^2) - 1)
contract CouponsForDollarsCalculator is ICouponsForDollarsCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;
    UbiquityAlgorithmicDollarManager public manager;

    /*   using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;*/

    /// @param _manager the address of the manager/config contract so we can fetch variables
    constructor(address _manager) {
        manager = UbiquityAlgorithmicDollarManager(_manager);
    }

    function getCouponAmount(uint256 dollarsToBurn)
        external
        view
        override
        returns (uint256)
    {
        require(
            DebtCoupon(manager.debtCouponAddress()).getTotalOutstandingDebt() <
                IERC20(manager.dollarTokenAddress()).totalSupply(),
            "Coupon to dollar: DEBT_TOO_HIGH"
        );
        bytes16 one = uint256(1).fromUInt();
        bytes16 totalDebt = DebtCoupon(manager.debtCouponAddress())
            .getTotalOutstandingDebt()
            .fromUInt();
        bytes16 r = totalDebt.div(
            IERC20(manager.dollarTokenAddress()).totalSupply().fromUInt()
        );

        bytes16 oneMinusRAllSquared = (one.sub(r)).mul(one.sub(r));

        bytes16 res = one.div(oneMinusRAllSquared);

        return res.mul(dollarsToBurn.fromUInt()).toUInt();
    }
}