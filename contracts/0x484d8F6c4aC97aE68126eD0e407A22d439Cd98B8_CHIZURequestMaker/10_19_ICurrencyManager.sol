// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Interface for functions the market uses Currency Manager
 */
interface ICurrencyManager {
    function depositETHFor(address account) external payable;

    function depositERC20For(
        address currency,
        address account,
        uint256 amount
    ) external;

    function withdrawETH(uint256 amount) external;

    function withdrawERC20(address currency, uint256 amount) external;

    /// @dev Use it to implement protocol fee
    function chizuReduceCurrencyFrom(
        address currency,
        address from,
        uint256 amount
    ) external;

    /// @dev Use it to implement owner fee / order fulfill
    function chizuTransferCurrencyFrom(
        address currency,
        address from,
        address to,
        uint256 amount
    ) external;

    function adminWithdrawAvailableETH() external;

    function adminWithdrawAvailableERC20(address currency) external;

    function adminChangeCurrencyWhitelist(address currency, bool isAvailable)
        external;

    function balanceOf(address currency, address account)
        external
        view
        returns (uint256);

    function isSupportedCurrency(address currency) external view returns (bool);
}