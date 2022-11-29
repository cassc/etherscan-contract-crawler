// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IProtocolConfig} from "IProtocolConfig.sol";
import {IERC4626} from "IERC4626.sol";
import {IDepositController} from "IDepositController.sol";
import {IWithdrawController} from "IWithdrawController.sol";
import {ITransferController} from "ITransferController.sol";
import {IERC165} from "IERC165.sol";

interface IPortfolio is IERC4626, IERC165 {
    function endDate() external view returns (uint256);

    function maxSize() external view returns (uint256);

    function liquidAssets() external view returns (uint256);
}