// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault is IERC20 {
    function deposit(uint256) external;

    function deposit(uint256 amount, address recipient) external returns (uint256);

    function deposit(
        uint256 amount,
        address recipient,
        bytes32 referral
    ) external returns (uint256);

    function withdraw(uint256) external;

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss,
        address endRecipient
    ) external returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint256);

    // V2
    function pricePerShare() external view returns (uint256);
}