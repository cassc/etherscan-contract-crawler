// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../interfaces/ISignatureMinting.sol";

interface IPropsERC20Rewards {
   function issueTokens(address _to, uint256 _amount) external;
}