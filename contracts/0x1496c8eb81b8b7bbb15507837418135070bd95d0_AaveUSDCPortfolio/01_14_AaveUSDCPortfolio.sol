//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import { Registry } from "../Registry.sol";
import { Entity } from "../Entity.sol";
import { Portfolio } from "../Portfolio.sol";
import { IAToken, ILendingPool } from "../interfaces/IAave.sol";
import { Auth } from "../lib/auth/Auth.sol";
import { Math } from "../lib/Math.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

error SyncAfterShutdown();

contract AaveUSDCPortfolio is Portfolio {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    ILendingPool public constant lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IAToken public constant ausdc = IAToken(0xBcca60bB61934080951369a648Fb03DF4F96263C);
    uint16 internal constant referralCode = 0; // Referral program is currently inactive.

    ERC20 public immutable usdc;

    error AssetMismatch();

    /**
     * @param _registry Endaoment registry.
     * @param _asset Underlying ERC20 asset token for portfolio.
     * @param _cap Amount of baseToken that this portfolio's asset balance should not exceed.
     * @param _redemptionFee Percentage fee as ZOC that should go to treasury on redemption. (100 = 1%).
     */
    constructor(
        Registry _registry,
        address _asset,
        uint256 _cap,
        uint256 _depositFee,
        uint256 _redemptionFee
    ) Portfolio(_registry, _asset, "Aave USDC Portfolio Shares", "aUSDC-PS", _cap, _depositFee, _redemptionFee) {
        usdc = registry.baseToken();
        if (address(usdc) != ausdc.UNDERLYING_ASSET_ADDRESS()) revert AssetMismatch(); // Sanity check.
        usdc.safeApprove(address(lendingPool), type(uint256).max);
    }

    /**
     * @notice Returns the USDC value of all aUSDC held by this contract.
     */
    function totalAssets() public view override returns (uint256) {
        return ausdc.balanceOf(address(this));
    }

    /**
     * @notice Takes some amount of assets from this portfolio as assets under management fee.
     * @param _amountAssets Amount of assets to take.
     */
    function takeFees(uint256 _amountAssets) external override requiresAuth {
        lendingPool.withdraw(address(usdc), _amountAssets, registry.treasury());
        emit FeesTaken(_amountAssets);
    }

    /**
     * @inheritdoc Portfolio
     * @dev Rounding down in both of these favors the portfolio, so the user gets slightly less and the portfolio gets slightly more,
     * that way it prevents a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number
     * due to rounding error.
     */
    function convertToShares(uint256 _assets) public view override returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _assets : _assets.mulDivDown(_supply, totalAssets());
    }

    /**
     * @inheritdoc Portfolio
     * @dev Rounding down in both of these favors the portfolio, so the user gets slightly less and the portfolio gets slightly more,
     * that way it prevents a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number
     * due to rounding error.
     */
    function convertToAssets(uint256 _shares) public view override returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _shares : _shares.mulDivDown(totalAssets(), _supply);
    }

    /**
     * @dev Rounding down in both of these favors the portfolio, so the user gets slightly less and the portfolio gets slightly more,
     * that way it prevents a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number
     * due to rounding error.
     */
    function convertToAssetsShutdown(uint256 _shares) public view returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _shares : _shares.mulDivDown(usdc.balanceOf(address(this)), _supply);
    }


    /**
     * @inheritdoc Portfolio
     * @dev Deposit the specified number of base token assets, subtract a fee, and deposit into Aave. The `_data`
     * parameter is unused.
     */
    function deposit(uint256 _amountBaseToken, bytes calldata /* _data */) external override returns (uint256) {
        if (didShutdown) revert DepositAfterShutdown();
        if (!_isEntity(Entity(msg.sender))) revert NotEntity();
        (uint256 _amountNet, uint256 _amountFee) = _calculateFee(_amountBaseToken, depositFee);
        if (totalAssets() + _amountNet > cap) revert ExceedsCap();

        uint256 _shares = convertToShares(_amountNet);
        if (_shares == 0) revert RoundsToZero();

        usdc.safeTransferFrom(msg.sender, address(this), _amountBaseToken);
        usdc.safeTransfer(registry.treasury(), _amountFee);
        _mint(msg.sender, _shares);
        emit Deposit(msg.sender, msg.sender, _amountNet, _shares, _amountBaseToken, _amountFee);

        lendingPool.deposit(address(usdc), _amountNet, address(this), referralCode);
        return _shares;
    }

     /**
     * @inheritdoc Portfolio
     * @dev Redeem the specified number of shares to get back the underlying base token assets, which are
     * withdrawn from Aave. If the utilization of the Aave market is too high, there may be insufficient
     * funds to redeem and this method will revert. The `_data` parameter is unused.
     */
    function redeem(uint256 _amountShares, bytes calldata /* _data */) external override returns (uint256) {
        if (didShutdown) return _redeemShutdown(_amountShares);
        uint256 _assets = convertToAssets(_amountShares);
        if (_assets == 0) revert RoundsToZero();

        lendingPool.withdraw(address(usdc), _assets, address(this));
        _burn(msg.sender, _amountShares);

        (uint256 _amountNet, uint256 _amountFee) = _calculateFee(_assets, depositFee);
        usdc.safeTransfer(registry.treasury(), _amountFee);
        usdc.safeTransfer(msg.sender, _amountNet);
        emit Redeem(msg.sender, msg.sender, _amountNet, _amountShares, _amountNet, _amountFee);
        return _amountNet;
    }

    /**
     * @notice Deposits stray USDC for the benefit of everyone else
     */
    function sync() external requiresAuth {
        if (didShutdown) revert SyncAfterShutdown();
        lendingPool.deposit(address(usdc), usdc.balanceOf(address(this)), address(this), referralCode);
    }

    /**
     * @inheritdoc Portfolio
     */
    function shutdown(bytes calldata /* data */) external override requiresAuth returns (uint256) {
        if (didShutdown) revert DidShutdown();
        uint256 _assetsOut = totalAssets();
        didShutdown = true;
        lendingPool.withdraw(address(usdc), _assetsOut, address(this));
        emit Shutdown(_assetsOut, _assetsOut);
        return _assetsOut;
    }

    /**
     * @notice Handles redemption after shutdown, exchanging shares for baseToken.
     * @param _amountShares Shares being redeemed.
     * @return Amount of baseToken received. 
     */
    function _redeemShutdown(uint256 _amountShares) private returns (uint256) {
        uint256 _baseTokenOut = convertToAssetsShutdown(_amountShares);
        _burn(msg.sender, _amountShares);
        (uint256 _netAmount, uint256 _fee) = _calculateFee(_baseTokenOut, redemptionFee);
        usdc.safeTransfer(registry.treasury(), _fee);
        usdc.safeTransfer(msg.sender, _netAmount);
        emit Redeem(msg.sender, msg.sender, _baseTokenOut, _amountShares, _netAmount, _fee);
        return _netAmount;
    }
}