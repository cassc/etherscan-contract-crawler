// SPDX-License-Identifier: BUSL-1.1

import "../external/interfaces/notional/INToken.sol";

pragma solidity 0.8.11;

interface INotionalStrategyContractHelper {
    function claimRewards(bool executeClaim) external returns(uint256);

    function deposit(uint256 amount) external returns(uint256);

    function withdraw(uint256 nTokenWithdraw) external returns(uint256);

    function withdrawAll() external returns (uint256);

    function nToken() external returns (INToken);
}