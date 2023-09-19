// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICellar is IERC20 {
    function asset() external view returns (address);

    /**
     * @notice The amount of assets that the cellar would exchange for the amount of shares provided.
     * @param shares amount of shares to convert
     * @return assets the shares can be exchanged for
     */
    function convertToAssets(uint256 shares) external view returns (uint256);

    /**
     * @notice After deposits users must wait `shareLockPeriod` time before being able to transfer or withdraw their shares.
     */
    function shareLockPeriod() external view returns (uint256);

    /**
     * @notice The total amount of withdrawable assets in the cellar.
     * @dev Run a re-entrancy check because totalAssetsWithdrawable can be wrong if re-entering from deposit/withdraws.
     */
    function totalAssetsWithdrawable() external view returns (uint256 assets);

    /**
     * @notice mapping that stores every users last time stamp they minted shares.
     */
    function userShareLockStartTime(address user) external view returns (uint256 lockTime);

    /**
     * @notice Deposits assets into the cellar, and returns shares to receiver.
     * @param assets amount of assets deposited by user.
     * @param receiver address to receive the shares.
     * @return shares amount of shares given for deposit.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @notice Withdraw assets from the cellar by redeeming shares.
     * @dev Unlike conventional ERC4626 contracts, this may not always return one asset to the receiver.
     *      Since there are no swaps involved in this function, the receiver may receive multiple
     *      assets. The value of all the assets returned will be equal to the amount defined by
     *      `assets` denominated in the `asset` of the cellar (eg. if `asset` is USDC and `assets`
     *      is 1000, then the receiver will receive $1000 worth of assets in either one or many
     *      tokens).
     * @param assets equivalent value of the assets withdrawn, denominated in the cellar's asset
     * @param receiver address that will receive withdrawn assets
     * @param owner address that owns the shares being redeemed
     * @return shares amount of shares redeemed
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}