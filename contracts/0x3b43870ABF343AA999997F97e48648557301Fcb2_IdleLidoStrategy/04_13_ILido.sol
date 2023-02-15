// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./IERC20Detailed.sol";

interface ILido is IERC20Detailed {
    function getOracle() external view returns (address);

    function getFee() external view returns (uint256);

    function submit(address _referral) external payable returns (uint256);
}