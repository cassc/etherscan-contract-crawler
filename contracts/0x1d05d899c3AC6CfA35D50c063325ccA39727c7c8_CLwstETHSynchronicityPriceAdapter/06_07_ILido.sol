// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";

interface ILido is IERC20Detailed {
    function getPooledEthByShares(uint256 _sharesAmount)
        external
        view
        returns (uint256);

    function getSharesByPooledEth(uint256 _pooledEth)
        external
        view
        returns (uint256);

    function submit(address _referral) external payable returns (uint256);
}