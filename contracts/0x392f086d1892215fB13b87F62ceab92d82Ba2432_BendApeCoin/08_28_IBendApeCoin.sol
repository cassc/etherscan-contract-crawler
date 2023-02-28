// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";

interface IBendApeCoin is IERC4626Upgradeable {
    function updateMinCompoundAmount(uint256 minAmount) external;

    function updateMinCompoundInterval(uint256 minInteval) external;

    function updateFeeRecipient(address recipient) external;

    function updateFee(uint256 fee) external;

    function compound() external;

    function claimAndDeposit(address[] calldata proxies) external returns (uint256);

    function assetBalanceOf(address account) external view returns (uint256);
}