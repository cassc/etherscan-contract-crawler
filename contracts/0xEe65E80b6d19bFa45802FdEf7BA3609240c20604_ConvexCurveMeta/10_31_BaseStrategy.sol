// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IStrategy.sol";

/**
 *
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy is IStrategy, ERC165 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  string public metadataURI;

  /**
   * @notice
   *  Used to track which version of `StrategyAPI` this Strategy
   *  implements.
   * @dev The Strategy's version must match the Vault's `API_VERSION`.
   * @return A string which holds the current API version of this contract.
   */
  function apiVersion() public pure returns (string memory) {
    return "0.0.1";
  }

  /**
   * @notice This Strategy's name.
   * @dev
   *  You can use this field to manage the "version" of this Strategy, e.g.
   *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
   *  `apiVersion()` function above.
   * @return This Strategy's name.
   */
  function name() external view virtual returns (string memory);

  /**
   * @notice
   *  The amount (priced in want) of the total assets managed by this strategy should not count
   *  towards Yearn's TVL calculations.
   * @dev
   *  You can override this field to set it to a non-zero value if some of the assets of this
   *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
   *  Note that this value must be strictly less than or equal to the amount provided by
   *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
   *  Also note that this value is used to determine the total assets under management by this
   *  strategy, for the purposes of computing the management fee in `Vault`
   * @return
   *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
   *  Locked (TVL) calculation across it's ecosystem.
   */
  function delegatedAssets() external view virtual returns (uint256) {
    return 0;
  }

  address public vault;
  address public strategyProposer;
  address public strategyDeveloper;
  address public harvester;
  IERC20 public want;

  // So indexers can keep track of this

  event UpdatedStrategyProposer(address strategyProposer);

  event UpdatedStrategyDeveloper(address strategyDeveloper);

  event UpdatedHarvester(address newHarvester);

  event UpdatedVault(address vault);

  event UpdatedMinReportDelay(uint256 delay);

  event UpdatedMaxReportDelay(uint256 delay);

  event UpdatedProfitFactor(uint256 profitFactor);

  event UpdatedDebtThreshold(uint256 debtThreshold);

  event UpdatedMetadataURI(string metadataURI);

  // The minimum number of seconds between harvest calls. See
  // `setMinReportDelay()` for more details.
  uint256 public minReportDelay;

  // The maximum number of seconds between harvest calls. See
  // `setMaxReportDelay()` for more details.
  uint256 public maxReportDelay;

  // The minimum multiple that `callCost` must be above the credit/profit to
  // be "justifiable". See `setProfitFactor()` for more details.
  uint256 public profitFactor;

  // Use this to adjust the threshold at which running a debt causes a
  // harvest trigger. See `setDebtThreshold()` for more details.
  uint256 public debtThreshold;

  // See note on `setEmergencyExit()`.
  bool public emergencyExit;

  // modifiers
  modifier onlyAuthorized() {
    require(
      msg.sender == strategyProposer || msg.sender == strategyDeveloper || msg.sender == governance(),
      "!authorized"
    );
    _;
  }

  modifier onlyStrategist() {
    require(msg.sender == strategyProposer || msg.sender == strategyDeveloper, "!strategist");
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance(), "!authorized");
    _;
  }

  modifier onlyKeepers() {
    require(
      msg.sender == harvester ||
        msg.sender == strategyProposer ||
        msg.sender == strategyDeveloper ||
        msg.sender == governance(),
      "!authorized"
    );
    _;
  }

  constructor(
    address _vault,
    address _strategyProposer,
    address _strategyDeveloper,
    address _harvester
  ) {
    _initialize(_vault, _strategyProposer, _strategyDeveloper, _harvester);
  }

  /**
   * @notice
   *  Initializes the Strategy, this is called only once, when the
   *  contract is deployed.
   * @dev `_vault` should implement `VaultAPI`.
   * @param _vault The address of the Vault responsible for this Strategy.
   */
  function _initialize(
    address _vault,
    address _strategyProposer,
    address _strategyDeveloper,
    address _harvester
  ) internal {
    require(address(want) == address(0), "Strategy already initialized");

    vault = _vault;
    want = IERC20(IVault(vault).token());
    checkWantToken();
    want.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
    strategyProposer = _strategyProposer;
    strategyDeveloper = _strategyDeveloper;
    harvester = _harvester;

    // initialize variables
    minReportDelay = 0;
    maxReportDelay = 86400;
    profitFactor = 100;
    debtThreshold = 0;
  }

  /**
   * @notice
   *  Used to change `_strategyProposer`.
   *
   *  This may only be called by governance or the existing strategist.
   * @param _strategyProposer The new address to assign as `strategist`.
   */
  function setStrategyProposer(address _strategyProposer) external onlyAuthorized {
    require(_strategyProposer != address(0), "! address 0");
    strategyProposer = _strategyProposer;
    emit UpdatedStrategyProposer(_strategyProposer);
  }

  function setStrategyDeveloper(address _strategyDeveloper) external onlyAuthorized {
    require(_strategyDeveloper != address(0), "! address 0");
    strategyDeveloper = _strategyDeveloper;
    emit UpdatedStrategyDeveloper(_strategyDeveloper);
  }

  /**
   * @notice
   *  Used to change `harvester`.
   *
   *  `harvester` is the only address that may call `tend()` or `harvest()`,
   *  other than `governance()` or `strategist`. However, unlike
   *  `governance()` or `strategist`, `harvester` may *only* call `tend()`
   *  and `harvest()`, and no other authorized functions, following the
   *  principle of least privilege.
   *
   *  This may only be called by governance or the strategist.
   * @param _harvester The new address to assign as `keeper`.
   */
  function setHarvester(address _harvester) external onlyAuthorized {
    require(_harvester != address(0), "! address 0");
    harvester = _harvester;
    emit UpdatedHarvester(_harvester);
  }

  function setVault(address _vault) external onlyAuthorized {
    require(_vault != address(0), "! address 0");
    vault = _vault;
    emit UpdatedVault(_vault);
  }

  /**
   * @notice
   *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
   *  of blocks that should pass for `harvest()` to be called.
   *
   *  For external keepers (such as the Keep3r network), this is the minimum
   *  time between jobs to wait. (see `harvestTrigger()`
   *  for more details.)
   *
   *  This may only be called by governance or the strategist.
   * @param _delay The minimum number of seconds to wait between harvests.
   */
  function setMinReportDelay(uint256 _delay) external onlyAuthorized {
    minReportDelay = _delay;
    emit UpdatedMinReportDelay(_delay);
  }

  /**
   * @notice
   *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
   *  of blocks that should pass for `harvest()` to be called.
   *
   *  For external keepers (such as the Keep3r network), this is the maximum
   *  time between jobs to wait. (see `harvestTrigger()`
   *  for more details.)
   *
   *  This may only be called by governance or the strategist.
   * @param _delay The maximum number of seconds to wait between harvests.
   */
  function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
    maxReportDelay = _delay;
    emit UpdatedMaxReportDelay(_delay);
  }

  /**
   * @notice
   *  Used to change `profitFactor`. `profitFactor` is used to determine
   *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
   *  for more details.)
   *
   *  This may only be called by governance or the strategist.
   * @param _profitFactor A ratio to multiply anticipated
   * `harvest()` gas cost against.
   */
  function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
    profitFactor = _profitFactor;
    emit UpdatedProfitFactor(_profitFactor);
  }

  /**
   * @notice
   *  Sets how far the Strategy can go into loss without a harvest and report
   *  being required.
   *
   *  By default this is 0, meaning any losses would cause a harvest which
   *  will subsequently report the loss to the Vault for tracking. (See
   *  `harvestTrigger()` for more details.)
   *
   *  This may only be called by governance or the strategist.
   * @param _debtThreshold How big of a loss this Strategy may carry without
   * being required to report to the Vault.
   */
  function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
    debtThreshold = _debtThreshold;
    emit UpdatedDebtThreshold(_debtThreshold);
  }

  /**
   * @notice
   *  Used to change `metadataURI`. `metadataURI` is used to store the URI
   * of the file describing the strategy.
   *
   *  This may only be called by governance or the strategist.
   * @param _metadataURI The URI that describe the strategy.
   */
  function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
    metadataURI = _metadataURI;
    emit UpdatedMetadataURI(_metadataURI);
  }

  /**
   * Resolve governance address from Vault contract, used to make assertions
   * on protected functions in the Strategy.
   */
  function governance() internal view returns (address) {
    return IVault(vault).governance();
  }

  /**
   * @notice
   *  Provide an accurate estimate for the total amount of assets
   *  (principle + return) that this Strategy is currently managing,
   *  denominated in terms of `want` tokens.
   *
   *  This total should be "realizable" e.g. the total value that could
   *  *actually* be obtained from this Strategy if it were to divest its
   *  entire position based on current on-chain conditions.
   * @dev
   *  Care must be taken in using this function, since it relies on external
   *  systems, which could be manipulated by the attacker to give an inflated
   *  (or reduced) value produced by this function, based on current on-chain
   *  conditions (e.g. this function is possible to influence through
   *  flashloan attacks, oracle manipulations, or other DeFi attack
   *  mechanisms).
   *
   *  It is up to governance to use this function to correctly order this
   *  Strategy relative to its peers in the withdrawal queue to minimize
   *  losses for the Vault based on sudden withdrawals. This value should be
   *  higher than the total debt of the Strategy and higher than its expected
   *  value to be "safe".
   * @return The estimated total assets in this Strategy.
   */
  function estimatedTotalAssets() public view virtual returns (uint256);

  /*
   * @notice
   *  Provide an indication of whether this strategy is currently "active"
   *  in that it is managing an active position, or will manage a position in
   *  the future. This should correlate to `harvest()` activity, so that Harvest
   *  events can be tracked externally by indexing agents.
   * @return True if the strategy is actively managing a position.
   */
  function isActive() public view returns (bool) {
    return IVault(vault).strategyDebtRatio(address(this)) > 0 || estimatedTotalAssets() > 0;
  }

  /*
   * @notice
   *  Support ERC165 spec to allow other contracts to query if a strategy has implemented IStrategy interface
   */
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return _interfaceId == type(IStrategy).interfaceId || super.supportsInterface(_interfaceId);
  }

  /// @notice check the want token to make sure it is the token that the strategy is expecting
  // solhint-disable-next-line no-empty-blocks
  function checkWantToken() internal view virtual {
    // by default this will do nothing. But child strategies can override this and validate the want token
  }

  /**
   * Perform any Strategy unwinding or other calls necessary to capture the
   * "free return" this Strategy has generated since the last time its core
   * position(s) were adjusted. Examples include unwrapping extra rewards.
   * This call is only used during "normal operation" of a Strategy, and
   * should be optimized to minimize losses as much as possible.
   *
   * This method returns any realized profits and/or realized losses
   * incurred, and should return the total amounts of profits/losses/debt
   * payments (in `want` tokens) for the Vault's accounting (e.g.
   * `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
   *
   * `_debtOutstanding` will be 0 if the Strategy is not past the configured
   * debt limit, otherwise its value will be how far past the debt limit
   * the Strategy is. The Strategy's debt limit is configured in the Vault.
   *
   * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
   *       It is okay for it to be less than `_debtOutstanding`, as that
   *       should only used as a guide for how much is left to pay back.
   *       Payments should be made to minimize loss from slippage, debt,
   *       withdrawal fees, etc.
   *
   * See `vault.debtOutstanding()`.
   */
  function prepareReturn(uint256 _debtOutstanding)
    internal
    virtual
    returns (
      uint256 _profit,
      uint256 _loss,
      uint256 _debtPayment
    );

  /**
   * Perform any adjustments to the core position(s) of this Strategy given
   * what change the Vault made in the "investable capital" available to the
   * Strategy. Note that all "free capital" in the Strategy after the report
   * was made is available for reinvestment. Also note that this number
   * could be 0, and you should handle that scenario accordingly.
   *
   * See comments regarding `_debtOutstanding` on `prepareReturn()`.
   */
  function adjustPosition(uint256 _debtOutstanding, bool claimRewards) internal virtual;

  /**
   * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
   * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
   * This function should return the amount of `want` tokens made available by the
   * liquidation. If there is a difference between them, `_loss` indicates whether the
   * difference is due to a realized loss, or if there is some other situation at play
   * (e.g. locked funds) where the amount made available is less than what is needed.
   * This function is used during emergency exit instead of `prepareReturn()` to
   * liquidate all of the Strategy's positions back to the Vault.
   *
   * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
   */
  function liquidatePosition(uint256 _amountNeeded, bool claimRewards)
    internal
    virtual
    returns (uint256 _liquidatedAmount, uint256 _loss);

  /**
   * @notice
   *  Provide a signal to the keeper that `tend()` should be called. The
   *  keeper will provide the estimated gas cost that they would pay to call
   *  `tend()`, and this function should use that estimate to make a
   *  determination if calling it is "worth it" for the keeper. This is not
   *  the only consideration into issuing this trigger, for example if the
   *  position would be negatively affected if `tend()` is not called
   *  shortly, then this can return `true` even if the keeper might be
   *  "at a loss" (keepers are always reimbursed by Yearn).
   * @dev
   *  `callCost` must be priced in terms of `want`.
   *
   *  This call and `harvestTrigger()` should never return `true` at the same
   *  time.
   * @return `true` if `tend()` should be called, `false` otherwise.
   */
  // solhint-disable-next-line no-unused-vars
  function tendTrigger(uint256) public view virtual returns (bool) {
    // We usually don't need tend, but if there are positions that need
    // active maintenance, overriding this function is how you would
    // signal for that.
    return false;
  }

  /**
   * @notice
   *  Adjust the Strategy's position. The purpose of tending isn't to
   *  realize gains, but to maximize yield by reinvesting any returns.
   *
   *  See comments on `adjustPosition()`.
   *
   *  This may only be called by governance, the strategist, or the keeper.
   */
  function tend() external onlyKeepers {
    adjustPosition(0, true);
  }

  /**
   * @notice
   *  Provide a signal to the keeper that `harvest()` should be called. The
   *  keeper will provide the estimated gas cost that they would pay to call
   *  `harvest()`, and this function should use that estimate to make a
   *  determination if calling it is "worth it" for the keeper. This is not
   *  the only consideration into issuing this trigger, for example if the
   *  position would be negatively affected if `harvest()` is not called
   *  shortly, then this can return `true` even if the keeper might be "at a
   *  loss" (keepers are always reimbursed by Yearn).
   * @dev
   *  `callCost` must be priced in terms of `want`.
   *
   *  This call and `tendTrigger` should never return `true` at the
   *  same time.
   *
   *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
   *  strategist-controlled parameters that will influence whether this call
   *  returns `true` or not. These parameters will be used in conjunction
   *  with the parameters reported to the Vault (see `params`) to determine
   *  if calling `harvest()` is merited.
   *
   *  It is expected that an external system will check `harvestTrigger()`.
   *  This could be a script run off a desktop or cloud bot (e.g.
   *  https://github.com/iearn-finance/yearn-vaults/blob/master/scripts/keep.py),
   *  or via an integration with the Keep3r network (e.g.
   *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
   * @param callCost The keeper's estimated cast cost to call `harvest()`.
   * @return `true` if `harvest()` should be called, `false` otherwise.
   */
  function harvestTrigger(uint256 callCost) public view virtual returns (bool) {
    StrategyInfo memory params = IVault(vault).strategy(address(this));

    // Should not trigger if Strategy is not activated
    if (params.activation == 0) return false;

    // Should not trigger if we haven't waited long enough since previous harvest
    if (timestamp().sub(params.lastReport) < minReportDelay) return false;

    // Should trigger if hasn't been called in a while
    if (timestamp().sub(params.lastReport) >= maxReportDelay) return true;

    // If some amount is owed, pay it back
    // NOTE: Since debt is based on deposits, it makes sense to guard against large
    //       changes to the value from triggering a harvest directly through user
    //       behavior. This should ensure reasonable resistance to manipulation
    //       from user-initiated withdrawals as the outstanding debt fluctuates.
    uint256 outstanding = IVault(vault).debtOutstanding(address(this));
    if (outstanding > debtThreshold) return true;

    // Check for profits and losses
    uint256 total = estimatedTotalAssets();
    // Trigger if we have a loss to report
    if (total.add(debtThreshold) < params.totalDebt) return true;

    uint256 profit = 0;
    if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

    // Otherwise, only trigger if it "makes sense" economically (gas cost
    // is <N% of value moved)
    uint256 credit = IVault(vault).creditAvailable(address(this));
    return (profitFactor.mul(callCost) < credit.add(profit));
  }

  /**
   * @notice All the strategy to do something when harvest is called.
   */
  // solhint-disable-next-line no-empty-blocks
  function onHarvest() internal virtual {}

  /**
   * @notice
   *  Harvests the Strategy, recognizing any profits or losses and adjusting
   *  the Strategy's position.
   *
   *  In the rare case the Strategy is in emergency shutdown, this will exit
   *  the Strategy's position.
   *
   *  This may only be called by governance, the strategist, or the keeper.
   * @dev
   *  When `harvest()` is called, the Strategy reports to the Vault (via
   *  `vault.report()`), so in some cases `harvest()` must be called in order
   *  to take in profits, to borrow newly available funds from the Vault, or
   *  otherwise adjust its position. In other cases `harvest()` must be
   *  called to report to the Vault on the Strategy's position, especially if
   *  any losses have occurred.
   */
  function harvest() external onlyKeepers {
    uint256 profit = 0;
    uint256 loss = 0;
    uint256 debtOutstanding = IVault(vault).debtOutstanding(address(this));
    uint256 debtPayment = 0;
    onHarvest();
    if (emergencyExit) {
      // Free up as much capital as possible
      uint256 totalAssets = estimatedTotalAssets();
      // NOTE: use the larger of total assets or debt outstanding to book losses properly
      (debtPayment, loss) = liquidatePosition(totalAssets > debtOutstanding ? totalAssets : debtOutstanding, true);
      // NOTE: take up any remainder here as profit
      if (debtPayment > debtOutstanding) {
        profit = debtPayment.sub(debtOutstanding);
        debtPayment = debtOutstanding;
      }
    } else {
      // Free up returns for Vault to pull
      (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
    }

    // Allow Vault to take up to the "harvested" balance of this contract,
    // which is the amount it has earned since the last time it reported to
    // the Vault.
    debtOutstanding = IVault(vault).report(profit, loss, debtPayment);

    // Check if free returns are left, and re-invest them
    adjustPosition(debtOutstanding, false);

    emit Harvested(profit, loss, debtPayment, debtOutstanding);
  }

  /**
   * @notice
   *  Withdraws `_amountNeeded` to `vault`.
   *
   *  This may only be called by the Vault.
   * @param _amountNeeded How much `want` to withdraw.
   * @return _loss Any realized losses
   */
  function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
    require(msg.sender == address(vault), "!vault");
    // Liquidate as much as possible to `want`, up to `_amountNeeded`
    uint256 amountFreed;
    (amountFreed, _loss) = liquidatePosition(_amountNeeded, false);
    // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
    want.safeTransfer(msg.sender, amountFreed);
    // NOTE: Reinvest anything leftover on next `tend`/`harvest`
  }

  /**
   * Do anything necessary to prepare this Strategy for migration, such as
   * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
   * value.
   */
  function prepareMigration(address _newStrategy) internal virtual;

  /**
   * @notice
   *  Transfers all `want` from this Strategy to `_newStrategy`.
   *
   *  This may only be called by governance or the Vault.
   * @dev
   *  The new Strategy's Vault must be the same as this Strategy's Vault.
   * @param _newStrategy The Strategy to migrate to.
   */
  function migrate(address _newStrategy) external {
    require(msg.sender == address(vault) || msg.sender == governance(), "!authorised");
    require(BaseStrategy(_newStrategy).vault() == vault, "invalid vault");
    prepareMigration(_newStrategy);
    want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
  }

  /**
   * @notice
   *  Activates emergency exit. Once activated, the Strategy will exit its
   *  position upon the next harvest, depositing all funds into the Vault as
   *  quickly as is reasonable given on-chain conditions.
   *
   *  This may only be called by governance or the strategist.
   * @dev
   *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
   */
  function setEmergencyExit() external onlyAuthorized {
    emergencyExit = true;
    IVault(vault).revokeStrategy();

    emit EmergencyExitEnabled();
  }

  /**
   * Override this to add all tokens/tokenized positions this contract
   * manages on a *persistent* basis (e.g. not just for swapping back to
   * want ephemerally).
   *
   * NOTE: Do *not* include `want`, already included in `sweep` below.
   *
   * Example:
   *
   *    function protectedTokens() internal override view returns (address[] memory) {
   *      address[] memory protected = new address[](3);
   *      protected[0] = tokenA;
   *      protected[1] = tokenB;
   *      protected[2] = tokenC;
   *      return protected;
   *    }
   */
  function protectedTokens() internal view virtual returns (address[] memory);

  /**
   * @notice
   *  Removes tokens from this Strategy that are not the type of tokens
   *  managed by this Strategy. This may be used in case of accidentally
   *  sending the wrong kind of token to this Strategy.
   *
   *  Tokens will be sent to `governance()`.
   *
   *  This will fail if an attempt is made to sweep `want`, or any tokens
   *  that are protected by this Strategy.
   *
   *  This may only be called by governance.
   * @dev
   *  Implement `protectedTokens()` to specify any additional tokens that
   *  should be protected from sweeping in addition to `want`.
   * @param _token The token to transfer out of this vault.
   */
  function sweep(address _token) external onlyGovernance {
    require(_token != address(want), "!want");
    require(_token != address(vault), "!shares");

    address[] memory _protectedTokens = protectedTokens();
    for (uint256 i; i < _protectedTokens.length; i++) {
      require(_token != _protectedTokens[i], "!protected");
    }

    IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
  }

  function timestamp() internal view virtual returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp;
  }
}