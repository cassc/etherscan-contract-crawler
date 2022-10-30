// SPDX-License-Identifier: BUSL-1.1

import "../external/interfaces/ICErc20.sol";

pragma solidity 0.8.11;

interface ICompoundStrategyContractHelper {
    function claimRewards(bool executeClaim) external returns(uint256);

    function deposit(uint256 amount) external returns(uint256);

    function withdraw(uint256 cTokenWithdraw) external returns(uint256);

    function withdrawAll(uint256[] calldata data) external returns (uint256);

    function cToken() external returns (ICErc20);
}