// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title  IWithdraw contract interface
 * @author Diagonal Finance
 * @notice Organization module. Encapsulates withdraw logic
 */
interface IWithdraw {
    function withdraw(
        address receiver,
        address token,
        uint256 amount,
        uint256 fee
    ) external;

    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_FEE_RECIPIENT() external view returns (address);
}