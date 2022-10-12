// SPDX-FileCopyrightText: 2020 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILido is IERC20Upgradeable {
    /**
     * @notice Adds eth to the pool
     * @return StETH Amount of StETH generated
     */
    function submit(address _referral) external payable returns (uint256 StETH);

    /**
     * @return the amount of shares that corresponds to `_ethAmount` protocol-controlled Ether.
     */
    function getSharesByPooledEth(uint256 _ethAmount)
        external
        view
        returns (uint256);

    /**
     * @return the amount of Ether that corresponds to `_sharesAmount` token shares.
     */
    function getPooledEthByShares(uint256 _sharesAmount)
        external
        view
        returns (uint256);

    //
    // NOT USED
    //

    function totalSupply() external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    /**
     * @notice Returns how much Ether can be staked in the current block
     * @dev Special return values:
     * - 2^256 - 1 if staking is unlimited;
     * - 0 if staking is paused or if limit is exhausted.
     */
    function getCurrentStakeLimit() external view returns (uint256);

    /**
     * @notice Gets the amount of Ether controlled by the system
     */
    function getTotalPooledEther() external view returns (uint256);

    /**
     * @notice Gets the amount of Ether temporary buffered on this contract balance
     */
    function getBufferedEther() external view returns (uint256);

    /**
     * @notice Returns the key values related to Beacon-side
     * @return depositedValidators - number of deposited validators
     * @return beaconValidators - number of Lido's validators visible in the Beacon state, reported by oracles
     * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of Lido validators)
     */
    function getBeaconStat()
        external
        view
        returns (
            uint256 depositedValidators,
            uint256 beaconValidators,
            uint256 beaconBalance
        );
}