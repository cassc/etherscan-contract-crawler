// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IBridgeRERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREUP is IBridgeRERC20, ICanMint, IUpgradeableBase
{
    function isREUP() external view returns (bool);
    function url() external view returns (string memory);
}