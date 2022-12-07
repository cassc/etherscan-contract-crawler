// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { IVault } from "../interfaces/IVault.sol";

/**
 * @title ETHAdapter
 * @notice A Proxy contract responsible for converting ETH into stETH and depositing into the Vault
 * @author Pods Finance
 */
contract ETHAdapter {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * @notice Curve's pool ETH <> stETH
     */
    ICurvePool public immutable pool;

    /**
     * @notice ETH coin index in the Curve Pool
     */
    int128 public constant ETH_INDEX = 0;

    /**
     * @notice stETH coin index in the Curve Pool
     */
    int128 public constant STETH_INDEX = 1;

    /**
     * @notice ETH token address representation
     */
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice stETH token address representation
     */
    address public constant STETH_ADDRESS = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    error ETHAdapter__IncompatibleVault();
    error ETHAdapter__IncompatiblePool();

    constructor(ICurvePool _pool) {
        if (
            _pool.coins(uint256(uint128(ETH_INDEX))) != ETH_ADDRESS ||
            _pool.coins(uint256(uint128(STETH_INDEX))) != STETH_ADDRESS
        ) revert ETHAdapter__IncompatiblePool();
        pool = _pool;
    }

    /**
     * @notice Convert `ethAmount` ETH to stETH using Curve pool
     * @param ethAmount Amount of ETH to convert
     * @return uint256 Amount of stETH received in exchange
     */
    function convertToSTETH(uint256 ethAmount) external view returns (uint256) {
        return pool.get_dy(ETH_INDEX, STETH_INDEX, ethAmount);
    }

    /**
     * @notice Convert 'stETHAmount' stETH to ETH using Curve pool
     * @param stETHAmount Amount of stETH to convert
     * @return uint256 Amount of ETH received in exchange
     */
    function convertToETH(uint256 stETHAmount) external view returns (uint256) {
        return pool.get_dy(STETH_INDEX, ETH_INDEX, stETHAmount);
    }

    /**
     * @notice Deposit `msg.value` of ETH, convert to stETH and deposit into `vault`
     * @param vault Pods' strategy vault that will receive the stETH
     * @param receiver Address that will be the owner of the Vault's shares
     * @param minOutput slippage control. Minimum acceptable amount of stETH
     * @return uint256 Amount of shares returned by vault ERC4626 contract
     */
    function deposit(
        IVault vault,
        address receiver,
        uint256 minOutput
    ) external payable returns (uint256) {
        if (vault.asset() != STETH_ADDRESS) revert ETHAdapter__IncompatibleVault();
        uint256 assets = pool.exchange{ value: msg.value }(ETH_INDEX, STETH_INDEX, msg.value, minOutput);
        IERC20(vault.asset()).safeIncreaseAllowance(address(vault), assets);
        return vault.deposit(assets, receiver);
    }

    /**
     * @notice Redeem `shares` shares, receive stETH, trade stETH for ETH and send to receiver
     * @param vault Pods' strategy vault that will receive the shares and payback stETH
     * @param shares Amount of Vault's shares to redeem
     * @param receiver Address that will receive back the ETH withdrawn from the `vault`
     * @param minOutput slippage control. Minimum acceptable amount of ETH
     * @return uint256 Amount of assets received from Vault ERC4626
     */
    function redeem(
        IVault vault,
        uint256 shares,
        address receiver,
        uint256 minOutput
    ) external returns (uint256) {
        uint256 assets = vault.redeem(shares, address(this), msg.sender);
        _returnETH(vault, receiver, minOutput);
        return assets;
    }

    /**
     * @notice redeemWithPermit `shares` shares, receive stETH, trade stETH for ETH and send to receiver
     * @dev Do not need to approve the shares in advance. The vault tokenized shares supports Permit
     * @param vault Pods' strategy vault that will receive the shares and payback stETH
     * @param shares Amount of Vault's shares to redeem
     * @param receiver Address that will receive back the ETH withdrawn from `vault`
     * @param minOutput slippage control. Minimum acceptable amount of ETH
     * @param deadline deadline that this transaction will be valid
     * @param v recovery id
     * @param r ECDSA signature output
     * @param s ECDSA signature output
     * @return assets Amount of assets received from Vault ERC4626
     */
    function redeemWithPermit(
        IVault vault,
        uint256 shares,
        address receiver,
        uint256 minOutput,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 assets) {
        vault.permit(msg.sender, address(this), shares, deadline, v, r, s);
        assets = vault.redeem(shares, address(this), msg.sender);
        _returnETH(vault, receiver, minOutput);
    }

    /**
     * @notice Withdraw `assets` assets, receive stETH, trade stETH for ETH and send to receiver
     * @dev Do not need to approve the shares in advance. The vault tokenized shares supports Permit
     * @param vault Pods' strategy vault that will receive the shares and payback stETH
     * @param assets Amount of assets (stETH) to redeem
     * @param receiver Address that will receive back the ETH withdrawn from the Vault
     * @param minOutput slippage control. Minimum acceptable amount of ETH
     * @return shares Amount of shares burned in order to receive assets
     */
    function withdraw(
        IVault vault,
        uint256 assets,
        address receiver,
        uint256 minOutput
    ) external returns (uint256 shares) {
        shares = vault.withdraw(assets, address(this), msg.sender);
        _returnETH(vault, receiver, minOutput);
    }

    /**
     * @notice withdrawWithPermit `assets` assets, receive stETH, trade stETH for ETH and send to receiver
     * @dev Do not need to approve the shares in advance. Vault's tokenized shares supports Permit
     * @param vault Pods' strategy vault that will receive the shares and payback stETH
     * @param assets Amount of assets (stETH) to redeem
     * @param receiver Address that will receive back the ETH withdrawn from the Vault
     * @param minOutput slippage control. Minimum acceptable amount of ETH
     * @param deadline deadline that this transaction will be valid
     * @param v recovery id
     * @param r ECDSA signature output
     * @param s ECDSA signature output
     * @return shares Amount of shares burned in order to receive assets
     */
    function withdrawWithPermit(
        IVault vault,
        uint256 assets,
        address receiver,
        uint256 minOutput,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares) {
        shares = vault.convertToShares(assets);
        vault.permit(msg.sender, address(this), shares, deadline, v, r, s);
        shares = vault.withdraw(assets, address(this), msg.sender);
        _returnETH(vault, receiver, minOutput);
    }

    /* We need this default function because this contract will
        receive ETH from the Curve pool
    */
    receive() external payable {}

    /**
     *  @dev internal function used to convert stETH into ETH and send back
     * to receiver
     */
    function _returnETH(
        IVault vault,
        address receiver,
        uint256 minOutput
    ) internal {
        if (vault.asset() != STETH_ADDRESS) revert ETHAdapter__IncompatibleVault();
        IERC20 asset = IERC20(vault.asset());

        uint256 balance = asset.balanceOf(address(this));
        asset.safeIncreaseAllowance(address(pool), balance);
        pool.exchange(STETH_INDEX, ETH_INDEX, balance, minOutput);

        payable(receiver).sendValue(address(this).balance);
    }
}