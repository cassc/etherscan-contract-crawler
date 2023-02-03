// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/drafts/ERC20Permit.sol";

import "../interfaces/ICurveLP.sol";
import "../protocol/core/ConfigOptions.sol";
import {GoldfinchConfig} from "../protocol/core/GoldfinchConfig.sol";
import {ConfigHelper} from "../protocol/core/ConfigHelper.sol";

contract TestFiduUSDCCurveLP is
  ERC20("LP FIDU-USDC Curve", "FIDUUSDCCURVE"),
  ERC20Permit("LP FIDU-USDC Curve"),
  ICurveLP
{
  using ConfigHelper for GoldfinchConfig;
  uint256 private constant MULTIPLIER_DECIMALS = 1e18;
  uint256 private constant USDC_DECIMALS = 1e6;

  GoldfinchConfig public config;

  uint256 private slippage = MULTIPLIER_DECIMALS;
  uint256[2] private _balances = [1e18, 1e18];
  uint256 private _totalSupply = 1e18;

  constructor(uint256 initialSupply, uint8 decimals, GoldfinchConfig _config) public {
    _setupDecimals(decimals);
    _mint(msg.sender, initialSupply);
    config = _config;
  }

  function coins(uint256 index) external view override returns (address) {
    // note: defining as an array so we get the same out of bounds behavior
    //        but can't define it at compile time because the addresses
    //        are sourced from goldfinch config
    return [address(getFidu()), address(getUSDC())][index];
  }

  function token() public view override returns (address) {
    return address(this);
  }

  /// @notice Mock calc_token_amount function that returns the sum of both token amounts
  function calc_token_amount(uint256[2] memory amounts) public view override returns (uint256) {
    return amounts[0].add(amounts[1].mul(MULTIPLIER_DECIMALS).div(USDC_DECIMALS));
  }

  /// @notice Mock add_liquidity function that mints Curve LP tokens
  function add_liquidity(
    uint256[2] memory amounts,
    uint256 min_mint_amount,
    bool,
    address receiver
  ) public override returns (uint256) {
    // Transfer FIDU and USDC from caller to this contract
    getFidu().transferFrom(msg.sender, address(this), amounts[0]);
    getUSDC().transferFrom(msg.sender, address(this), amounts[1]);

    uint256 amount = calc_token_amount(amounts).mul(slippage).div(MULTIPLIER_DECIMALS);

    require(amount >= min_mint_amount, "Slippage too high");

    _mint(receiver, amount);
    return amount;
  }

  function lp_price() external view override returns (uint256) {
    return MULTIPLIER_DECIMALS.mul(2);
  }

  /// @notice Used to mock slippage in unit tests
  function _setSlippage(uint256 newSlippage) external {
    slippage = newSlippage;
  }

  /// @notice Used to return the mocked balances in unit tests
  function balances(uint256 index) public view override returns (uint256) {
    return _balances[index];
  }

  /// @notice Used to mock balances in unit tests
  function _setBalance(uint256 index, uint256 balance) public {
    _balances[index] = balance;
  }

  /// @notice Used to return the mocked total supply in unit tests
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /// @notice Used to mock the total supply in unit tests
  function _setTotalSupply(uint256 newTotalSupply) public {
    _totalSupply = newTotalSupply;
  }

  /// @notice Mock remove_liquidity function
  /// @dev Left unimplemented because we're only using this in mainnet forking tests
  function remove_liquidity(uint256, uint256[2] memory) public override returns (uint256) {
    return 0;
  }

  /// @notice Mock remove_liquidity_one_coin function
  /// @dev Left unimplemented because we're only using this in mainnet forking tests
  function remove_liquidity_one_coin(uint256, uint256, uint256) public override returns (uint256) {
    return 0;
  }

  /// @notice Mock get_dy function
  /// @dev Left unimplemented because we're only using this in mainnet forking tests
  function get_dy(uint256, uint256, uint256) external view override returns (uint256) {
    return 0;
  }

  /// @notice Mock exchange function
  /// @dev Left unimplemented because we're only using this in mainnet forking tests
  function exchange(uint256, uint256, uint256, uint256) public override returns (uint256) {
    return 0;
  }

  function getUSDC() internal view returns (ERC20) {
    return ERC20(address(config.getUSDC()));
  }

  function getFidu() internal view returns (ERC20) {
    return ERC20(address(config.getFidu()));
  }
}