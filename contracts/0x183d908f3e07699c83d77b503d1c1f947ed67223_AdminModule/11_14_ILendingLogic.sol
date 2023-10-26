// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title ILendingLogic
 * @author Cian
 * @notice Define the interface for the lending logic.
 */
interface ILendingLogic {
    enum PROTOCOL {
        PROTOCOL_AAVEV2,
        PROTOCOL_AAVEV3,
        PROTOCOL_COMPOUNDV3,
        PROTOCOL_MORPHO_AAVEV2
    }

    function deposit(uint8 _protocolId, address asset, uint256 amount) external;

    function withdraw(uint8 _protocolId, address asset, uint256 amount) external;

    function borrow(uint8 _protocolId, address asset, uint256 amount) external;

    function repay(uint8 _protocolId, address asset, uint256 amount) external;

    function enterProtocol(uint8 _protocolId) external;

    function exitProtocol(uint8 _protocolId) external;

    function getAvailableBorrowsETH(uint8 _protocolId, address _account) external view returns (uint256);

    function getAvailableWithdrawsStETH(uint8 _protocolId, address _account) external view returns (uint256);

    function getProtocolCollateralRatio(uint8 _protocolId, address _account) external view returns (uint256 ratio);

    function getProtocolLeverageAmount(
        uint8 _protocolId,
        address _account,
        bool _isDepositOrWithdraw,
        uint256 _depositOrWithdraw,
        uint256 _safeRatio
    ) external view returns (bool isLeverage, uint256 amount);

    function getProtocolAccountData(uint8 _protocolId, address _account)
        external
        view
        returns (uint256 stEthAmount, uint256 debtEthAmount);

    function getNetAssetsInfo(address _account)
        external
        view
        returns (uint256 totalAssets, uint256 totalDebt, uint256 netAssets, uint256 aggregatedRatio);
}