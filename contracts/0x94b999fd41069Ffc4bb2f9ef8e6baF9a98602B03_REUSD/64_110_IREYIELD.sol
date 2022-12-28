// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IBridgeSelfStakingERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREYIELD is IBridgeSelfStakingERC20, ICanMint, IUpgradeableBase
{
    function isREYIELD() external view returns (bool);
    function url() external view returns (string memory);
}