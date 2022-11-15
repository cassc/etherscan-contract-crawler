// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// @notice Interface for Yearn Vault tokens
// @dev see https://github.com/yearn/yearn-vaults/blob/main/contracts/Vault.vy
interface IYearnVault {
    // @dev Used to redeem yvTokens for underlying
    function withdraw() external returns (uint256);

    // @dev Returns address of underlying token
    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);
}