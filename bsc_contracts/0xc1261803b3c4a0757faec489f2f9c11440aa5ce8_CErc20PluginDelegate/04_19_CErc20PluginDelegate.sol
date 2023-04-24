// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./CErc20Delegate.sol";
import "./EIP20Interface.sol";
import "./IERC4626.sol";
import "../external/uniswap/IUniswapV2Pair.sol";

/**
 * @title Rari's CErc20Plugin's Contract
 * @notice CToken which outsources token logic to a plugin
 * @author Joey Santoro
 *
 * CErc20PluginDelegate deposits and withdraws from a plugin contract
 * It is also capable of delegating reward functionality to a PluginRewardsDistributor
 */
contract CErc20PluginDelegate is CErc20Delegate {
  event NewPluginImplementation(address oldImpl, address newImpl);

  /**
   * @notice Plugin address
   */
  IERC4626 public plugin;

  /**
   * @notice Delegate interface to become the implementation
   * @param data The encoded arguments for becoming
   */
  function _becomeImplementation(bytes memory data) public virtual override {
    require(msg.sender == address(this) || hasAdminRights(), "only self and admins can call _becomeImplementation");

    address _plugin = abi.decode(data, (address));

    if (_plugin == address(0) && address(plugin) != address(0)) {
      // if no new plugin address is given, use the latest implementation
      _plugin = IFuseFeeDistributor(fuseAdmin).latestPluginImplementation(address(plugin));
    }

    if (_plugin != address(0) && _plugin != address(plugin)) {
      _updatePlugin(_plugin);
    }
  }

  /**
   * @notice Update the plugin implementation to a whitelisted implementation
   * @param _plugin The address of the plugin implementation to use
   */
  function _updatePlugin(address _plugin) public {
    require(msg.sender == address(this) || hasAdminRights(), "only self and admins can call _updatePlugin");

    address oldImplementation = address(plugin) != address(0) ? address(plugin) : _plugin;

    require(
      IFuseFeeDistributor(fuseAdmin).pluginImplementationWhitelist(oldImplementation, _plugin),
      "plugin implementation not whitelisted"
    );

    if (address(plugin) != address(0) && plugin.balanceOf(address(this)) != 0) {
      plugin.redeem(plugin.balanceOf(address(this)), address(this), address(this));
    }

    plugin = IERC4626(_plugin);

    EIP20Interface(underlying).approve(_plugin, type(uint256).max);

    uint256 amount = EIP20Interface(underlying).balanceOf(address(this));
    if (amount != 0) {
      deposit(amount);
    }

    emit NewPluginImplementation(address(plugin), _plugin);
  }

  /*** CToken Overrides ***/

  /*** Safe Token ***/

  /**
   * @notice Gets balance of the plugin in terms of the underlying
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() internal view override returns (uint256) {
    return plugin.previewRedeem(plugin.balanceOf(address(this)));
  }

  /**
   * @notice Transfer the underlying to the cToken and trigger a deposit
   * @param from Address to transfer funds from
   * @param amount Amount of underlying to transfer
   * @return The actual amount that is transferred
   */
  function doTransferIn(address from, uint256 amount) internal override returns (uint256) {
    // Perform the EIP-20 transfer in
    require(EIP20Interface(underlying).transferFrom(from, address(this), amount), "send");

    deposit(amount);
    return amount;
  }

  function deposit(uint256 amount) internal {
    plugin.deposit(amount, address(this));
  }

  /**
   * @notice Transfer the underlying from plugin to destination
   * @param to Address to transfer funds to
   * @param amount Amount of underlying to transfer
   */
  function doTransferOut(address to, uint256 amount) internal override {
    plugin.withdraw(amount, to, address(this));
  }

  function contractType() external pure virtual override returns (string memory) {
    return "CErc20PluginDelegate";
  }
}