// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWSTETH is IERC20Metadata {
    /**
     * @notice Exchanges wstEth to stEth
     * @param _wstEthAmount amount of wstEth to uwrap in exchange for stEth
     * @dev Requirements:
     *  - `_wstEthAmount` must be non-zero
     *  - msg.sender must have at least `_wstEthAmount` wstEth.
     * @return Amount of stEth user receives after unwrap
     */
    function unwrap(uint256 _wstEthAmount) external returns (uint256);
}

interface ISTETH is IERC20Metadata {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}