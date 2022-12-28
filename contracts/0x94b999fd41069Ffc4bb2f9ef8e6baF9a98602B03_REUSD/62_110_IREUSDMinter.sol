// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Base/IREUSDMinterBase.sol";

interface IREUSDMinter is IUpgradeableBase, IREUSDMinterBase
{
    function isREUSDMinter() external view returns (bool);

    function mint(IERC20 paymentToken, uint256 reusdAmount) external;
    function mintPermit(IERC20Full paymentToken, uint256 reusdAmount, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function mintTo(IERC20 paymentToken, address recipient, uint256 reusdAmount) external;
}