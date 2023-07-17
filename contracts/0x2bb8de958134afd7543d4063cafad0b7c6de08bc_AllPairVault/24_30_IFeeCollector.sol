// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeCollector {
  function processFee(
    uint256 vaultId,
    IERC20 token,
    uint256 feeSent
  ) external;
}