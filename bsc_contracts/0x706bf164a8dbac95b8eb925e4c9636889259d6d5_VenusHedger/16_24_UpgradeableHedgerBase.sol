// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.10;

import { UUPSUpgradeable } from 'openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import { PausableUpgradeable } from 'openzeppelin-upgradeable/security/PausableUpgradeable.sol';
import { OwnableUpgradeable } from 'openzeppelin-upgradeable/access/OwnableUpgradeable.sol';
import { Initializable } from 'openzeppelin-upgradeable/proxy/utils/Initializable.sol';
import { console } from 'forge-std/console.sol';

import { IParaSwapAugustus } from '../external/paraswap/IParaSwapAugustus.sol';
import { Config } from '../components/Config.sol';
import { IHedger } from '../interfaces/IHedger.sol';
import { IERC20 } from '../interfaces/tokens/IERC20.sol';

error NOT_IMPLEMENTED(string func);

abstract contract UpgradeableHedgerBase is
  IHedger,
  Initializable,
  UUPSUpgradeable,
  PausableUpgradeable,
  OwnableUpgradeable
{
  /// @dev Paraswap proxy contract for swaps.
  ///      All chains have the same address: 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57.
  ///      Must be initialized in `initialize` function of each inheriting contract.
  IParaSwapAugustus public paraswap;

  address public paraswapTokenProxy; // token transfer proxy (need to approve this addr for tokens)

  Config public config;

  bool public isContractUpgradeable = true;

  IERC20 public USDC; // modified in `initialize` so can't use immutable modifier

  uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

  modifier onlyUpgradeable() {
    require(isContractUpgradeable, 'Contract is not upgradeable.');
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  //
  // UUPS Implementation
  //

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _authorizeUpgrade(
    address newImplementation
  )
    internal
    override
    onlyOwner
    onlyUpgradeable // additional check
  {}

  function getImplementation() external view returns (address) {
    return _getImplementation();
  }

  /// @dev Proxy logic
  function setContractUpgradeable(bool _isContractUpgradeable) public onlyOwner {
    isContractUpgradeable = _isContractUpgradeable;
  }

  //
  // Ownership Guard
  //

  function transferOwnership(address newOwner) public virtual override onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    // require(potentialOwners.contains(newOwner), 'New owner is not a potential owner');
    require(
      newOwner == address(0x66D5eEaFbb36B976967B9C2f0FceAA18B339A64C) ||
        newOwner == address(0xFF40b156a428758e2d37d95BBC3D1e185a394A66),
      'New owner is not a potential owner'
    );
    _transferOwnership(newOwner);
  }

  //
  // Base Contract Logic
  //

  function setConfig(address _config, address _augustus) public onlyOwner {
    config = Config(_config);
    paraswap = IParaSwapAugustus(_augustus);
    paraswapTokenProxy = paraswap.getTokenTransferProxy();
  }

  function setERC20Allowance(address token, address spender, uint256 amount) public onlyOwner {
    IERC20(token).approve(spender, amount);
  }

  function _canHedge(
    address token,
    uint256 amountUSDC, // 1e18
    uint256 availableCollateral, // 1e18
    uint256 buffer
  ) internal view returns (bool possible, uint256 shortfall) {
    // amountUSDC with buffer added, e.g. BUFFER: 0.1% (1001/1000)
    // amountUSDC = ((amountUSDC / (10 ** 18)) * (10000 + buffer)) / 10000;
    amountUSDC = (amountUSDC * (10000 + buffer)) / 10000;

    // Used to round (shave off) very small decimals when enforcing collateral ltv
    uint rounder = 10 ** (IERC20(token).decimals() - USDC.decimals());

    uint requiredCollateral = (mulDivUp(amountUSDC, 1e4, config.LTV()) / rounder) * rounder;
    // Multiplication -- 10^18: division precision holder ==> 10^18
    // Division -- 10^4: Rounding buffer; division precision holder ==> 10^22
    uint bufferedRequired = (mulDivUp(requiredCollateral, config.roundingBuffer(), 1e4) / rounder) * rounder;

    console.log('amountUSDC', amountUSDC);
    console.log('availableCollateral', availableCollateral);
    console.log('requiredCollateral', requiredCollateral);
    console.log('bufferedRequired', bufferedRequired);

    // IF: Not enough collateral, need to deposit collateral
    // ELSE: possible to hedge
    if (bufferedRequired > availableCollateral)
      shortfall = (requiredCollateral - availableCollateral) / (10 ** (IERC20(token).decimals() - USDC.decimals()));
    else possible = true;
  }

  /// @dev Check if contract has enough USDC to pay back the hedge (swap USDC to token/vToken and repay)
  function canPayback(uint256 maxAmountToSwap) public view returns (bool possible, uint256 shortfall) {
    uint beforeUSDC = USDC.balanceOf(address(this));

    // IF: not enough baalnce to cover maxAmounToSwap for USDC
    // ELSE: possible to payback
    if (beforeUSDC < maxAmountToSwap) shortfall = maxAmountToSwap - beforeUSDC;
    else possible = true;
  }

  function swap(bytes memory swapCalldata) public onlyOwner {
    // Swap via ParaSwap
    (bool success, ) = address(paraswap).call(swapCalldata);
    if (!success) {
      // Copy revert reason from call
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  function depositCollateral(uint256 /* amount */) public virtual {
    revert NOT_IMPLEMENTED('depositCollateral');
  }

  // Override in Implementation
  function hedge(
    IERC20 /* token */, // example: ETH
    bytes memory /* swapCalldata */,
    uint256 /* amountToSwap */, // amount of token to hedge & swap
    uint256 /* minAmountToReceiveUSDC */
  ) public virtual returns (uint256) {
    // amountReceived
    revert NOT_IMPLEMENTED('hedge');
  }

  // Override in Implementation
  function payback(
    IERC20 /* token */, // example: ETH
    bytes memory /* swapCalldata */,
    uint256 /* maxAmountToSwapUSDC */, // max amount of USDC to swap
    uint256 /* amountToReceiveToken */ // amount of token to receive
  ) public virtual returns (uint256 /* amountSold */) {
    revert NOT_IMPLEMENTED('payback');
  }

  function _hedgeSwapStep(
    IERC20 token, // swap this toke nto USDC
    bytes memory swapCalldata,
    uint256 amountToSwapToken, // expected amount of token to hedge & swap
    uint256 minAmountToReceiveUSDC // min amount of USDC to receive
  ) internal returns (uint256 amountReceived) {
    // Before swap checks
    uint balanceBeforeAssetFrom = token.balanceOf(address(this));
    uint balanceBeforeUSDC = USDC.balanceOf(address(this));

    // Swap via ParaSwap
    swap(swapCalldata); // swap token to USDC (receive USDC)

    // After swap checks
    require(token.balanceOf(address(this)) == balanceBeforeAssetFrom - amountToSwapToken, 'WRONG_BALANCE_AFTER_SWAP');
    require(
      USDC.balanceOf(address(this)) >= balanceBeforeUSDC + minAmountToReceiveUSDC,
      'INSUFFICIENT_AMOUNT_RECEIVED'
    );

    // USDC received from shorting the borrowed token (hedged)
    amountReceived = USDC.balanceOf(address(this)) - balanceBeforeUSDC;
  }

  function _paybackSwapStep(
    IERC20 token, // swap USDC to this token
    bytes memory swapCalldata,
    uint256 maxAmountToSwapUSDC, // max amount of USDC to swap to token
    uint256 amountToReceiveToken // expected amount of token to receive
  ) internal returns (uint256 amountSold) {
    if (address(token) != address(USDC)) {
      uint balanceBeforeUSDC = USDC.balanceOf(address(this));
      require(balanceBeforeUSDC >= maxAmountToSwapUSDC, 'INSUFFICIENT_BALANCE_BEFORE_SWAP');

      if (token.balanceOf(address(this)) < amountToReceiveToken) {
        uint balanceBeforeAssetTo = token.balanceOf(address(this));

        swap(swapCalldata); // swap USDC to token (receive token)

        // After swap checks
        require(
          token.balanceOf(address(this)) >= balanceBeforeAssetTo + amountToReceiveToken,
          'INSUFFICIENT_AMOUNT_RECEIVED'
        );

        amountSold = balanceBeforeUSDC - USDC.balanceOf(address(this));
        require(amountSold <= maxAmountToSwapUSDC, 'WRONG_BALANCE_AFTER_SWAP');
      }
    }
  }

  /// @dev Deposit USDC and then hedge.
  function depositAndHedge(
    IERC20 token,
    bytes memory swapCalldata,
    uint256 amountToSwap, // always constant
    uint256 minAmountToReceiveUSDC,
    uint256 amount // amount of USDC to deposit
  ) public onlyOwner {
    if (amount > 0) depositCollateral(amount);
    hedge(token, swapCalldata, amountToSwap, minAmountToReceiveUSDC);
  }

  /// @dev Deposit USDC and then payback.
  function depositAndPayback(
    IERC20 token,
    bytes memory swapCalldata,
    uint256 maxAmountToSwapUSDC, // max amount of USDC to swap
    uint256 amountToReceiveToken, // amount of token to receive
    uint256 amount // amount of USDC to deposit
  ) public onlyOwner {
    if (amount > 0) {
      require(USDC.allowance(msg.sender, address(this)) >= amount, 'DAP: Insufficient USDC allowance');
      USDC.transferFrom(msg.sender, address(this), amount);
    }
    payback(token, swapCalldata, maxAmountToSwapUSDC, amountToReceiveToken);
  }

  /// @dev Amount + amount * slippage
  /// @param a Amount of token
  /// @param s Desired slippage in 10^4 (e.g. 0.01% => 0.01e4 => 100)
  function _amountMoreSlippage(uint256 a, uint256 s) internal pure returns (uint256) {
    // slippage: 0.5e4 (0.5%)
    return (a * (10 ** 6 + s)) / 10 ** 6;
  }

  function withdrawERC(address token, uint256 amount) public onlyOwner {
    IERC20(token).transfer(msg.sender, amount);
  }

  function withdrawERCAll(address token) public onlyOwner {
    withdrawERC(token, IERC20(token).balanceOf(address(this)));
  }

  function approveERC(address token, address spender, uint256 amount) public onlyOwner {
    IERC20(token).approve(spender, amount);
  }

  function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
      if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
        revert(0, 0)
      }

      // If x * y modulo the denominator is strictly greater than 0,
      // 1 is added to round up the division of x * y by the denominator.
      z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
    }
  }

  // payable
  fallback() external payable {}
  receive() external payable {}
}