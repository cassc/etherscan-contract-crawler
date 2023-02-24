// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../basic/IGameFiTokenERC20.sol";

interface IGameFiWrapperERC20 is IGameFiTokenERC20 {
    event RecoverTo(address indexed sender, uint256 amount, uint256 timestamp);

    function recoverTo(address account, uint256 amount) external;

    function cap() external view returns (uint256);

    function leftToMint() external view returns (uint256);
}