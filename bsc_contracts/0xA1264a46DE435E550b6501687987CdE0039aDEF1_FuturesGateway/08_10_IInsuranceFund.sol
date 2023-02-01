// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IInsuranceFund {
    function deposit(
        address positionManager,
        address trader,
        uint256 depositAmount,
        uint256 fee
    ) external;

    function depositWithBonus(
        address _positionManager,
        address _trader,
        uint256 _realInitialMargin,
        uint256 _bonusInitialMargin,
        uint256 _fee
    ) external;

    function calculateBusdBonusAmount(
        address _positionManager,
        address _trader,
        uint256 _initialMargin,
        uint256 _fee,
        uint256 _notional
    )
        external
        view
        returns (
            uint256 _realMarginNeeded,
            uint256 _bonusMarginNeededWithFee,
            uint256 _bonusMarginNeeded,
            bool _isSufficientCollateral
        );

    function withdraw(
        address positionManager,
        address trader,
        uint256 amount
    ) external;

    function buyBackAndBurn(address token, uint256 amount) external;

    function transferFeeFromTrader(
        address token,
        address trader,
        uint256 amountFee
    ) external;

    function reduceBonus(
        address _positionManager,
        address _trader,
        uint256 _reduceAmount
    ) external;

    function liquidateAndDistributeReward(
        address _positionManager,
        address _liquidator,
        address _trader,
        uint256 _liquidatedBusdBonus,
        uint256 _liquidatorReward
    ) external;
}