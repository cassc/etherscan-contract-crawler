// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITreasury {
    function hasPool(address _address) external view returns (bool);

    function minting_fee() external view returns (uint256);

    function redemption_fee() external view returns (uint256);

    function reserve_farming_percent() external view returns (uint256);

    function collateralReserve() external view returns (address);

    function globalMainCollateralBalance() external view returns (uint256);

    function globalMainCollateralValue() external view returns (uint256);

    function globalSecondCollateralBalance() external view returns (uint256);

    function globalSecondCollateralValue() external view returns (uint256);

    function globalCollateralTotalValue() external view returns (uint256);

    function getEffectiveCollateralRatio() external view returns (uint256);

    function requestTransfer(address token, address receiver, uint256 amount) external;

    function reserveReceiveCollaterals(uint256 _mainCollateralAmount, uint256 _secondCollateralAmount) external;

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}