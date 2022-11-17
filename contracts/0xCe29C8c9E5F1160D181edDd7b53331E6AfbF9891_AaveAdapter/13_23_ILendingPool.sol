// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "./library/DataTypes.sol";

interface ILendingPool {
    function deposit(
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external;

    function withdraw(
        address _asset,
        uint256 _amount,
        address _to
    ) external;

    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;

    function repay(
        address _asset,
        uint256 _amount,
        uint256 _rateMode,
        address _onBehalfOf
    ) external;

    function setUserUseReserveAsCollateral(
        address _asset,
        bool _useAsCollateral
    ) external;

    function swapBorrowRateMode(address _asset, uint256 _rateMode) external;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);
}