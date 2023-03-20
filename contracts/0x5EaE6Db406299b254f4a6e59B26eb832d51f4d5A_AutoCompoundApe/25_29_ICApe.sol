// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "../dependencies/openzeppelin/contracts/IERC20.sol";

interface ICApe is IERC20 {
    /**
     * @return the amount of shares that corresponds to `amount` protocol-controlled Ape.
     */
    function getShareByPooledApe(uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @return the amount of Ape that corresponds to `sharesAmount` token shares.
     */
    function getPooledApeByShares(uint256 sharesAmount)
        external
        view
        returns (uint256);

    /**
     * @return the amount of shares belongs to _account.
     */
    function sharesOf(address _account) external view returns (uint256);
}