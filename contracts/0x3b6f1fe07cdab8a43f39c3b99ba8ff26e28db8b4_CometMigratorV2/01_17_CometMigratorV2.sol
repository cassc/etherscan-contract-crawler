// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./vendor/@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "./vendor/@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./vendor/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./vendor/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/AaveInterface.sol";
import "./interfaces/CTokenInterface.sol";
import "./interfaces/CometInterface.sol";
import "./interfaces/IWETH9.sol";

/**
 * @title Compound III Migrator v2
 * @notice A contract to help migrate a Compound II or Aave v2 position into a similar Compound III position.
 * @author Compound
 */
contract CometMigratorV2 is IUniswapV3FlashCallback {
  error Reentrancy(uint256 loc);
  error CompoundV2Error(uint256 loc, uint256 code);
  error SweepFailure(uint256 loc);
  error CTokenTransferFailure();
  error InvalidConfiguration(uint256 loc);
  error InvalidCallback(uint256 loc);
  error InvalidInputs(uint256 loc);
  error ERC20TransferFailure(uint256 loc);

  /** Events **/
  event Migrated(
    address indexed user,
    CompoundV2Position compoundV2Position,
    AaveV2Position aaveV2Position,
    uint256 flashAmount,
    uint256 flashAmountWithFee);

  event Sweep(
    address indexed sweeper,
    address indexed recipient,
    address indexed asset,
    uint256 amount);

  /// @notice Represents the configuration for executing a Uniswap swap.
  struct Swap {
    bytes path; // empty path if no swap is required (e.g. repaying USDC borrow)
    uint256 amountInMaximum; // Note: Can be set as `type(uint256).max`
  }

  /// @notice Represents an entire Compound II position (collateral + borrows) to migrate.
  struct CompoundV2Position {
    CompoundV2Collateral[] collateral;
    CompoundV2Borrow[] borrows;
    Swap[] swaps;
  }

  /// @notice Represents a given amount of Compound II collateral to migrate.
  struct CompoundV2Collateral {
    CTokenLike cToken;
    uint256 amount; // Note: This is the amount of the cToken
  }

  /// @notice Represents a given amount of Compound II borrow to migrate.
  struct CompoundV2Borrow {
    CTokenLike cToken;
    uint256 amount; // Note: This is the amount of the underlying, not the cToken
  }

  /// @notice Represents an entire Aave v2 position (collateral + borrows) to migrate.
  struct AaveV2Position {
    AaveV2Collateral[] collateral;
    AaveV2Borrow[] borrows;
    Swap[] swaps;
  }

  /// @notice Represents a given amount of Aave v2 collateral to migrate.
  struct AaveV2Collateral {
    ATokenLike aToken;
    uint256 amount;
  }

  /// @notice Represents a given amount of Aave v2 borrow to migrate.
  struct AaveV2Borrow {
    ADebtTokenLike aDebtToken; // Note: Aave has two separate debt tokens per asset: stable and variable rate
    uint256 amount;
  }

  /// @notice Represents all data required to continue operation after a flash loan is initiated.
  struct MigrationCallbackData {
    address user;
    uint256 flashAmount;
    CompoundV2Position compoundV2Position;
    AaveV2Position aaveV2Position;
  }

  /// @notice The Comet Ethereum mainnet USDC contract
  Comet public immutable comet;

  /// @notice The Uniswap pool used by this contract to source liquidity (i.e. flash loans).
  IUniswapV3Pool public immutable uniswapLiquidityPool;

  /// @notice True if borrow token is token 0 in the Uniswap liquidity pool, otherwise false if token 1.
  bool public immutable isUniswapLiquidityPoolToken0;

  /// @notice Uniswap router used for token swaps.
  ISwapRouter public immutable swapRouter;

  /// @notice The underlying borrow token (e.g. `USDC`).
  IERC20NonStandard public immutable baseToken;

  /// @notice The address of the `cETH` token.
  CTokenLike public immutable cETH;

  /// @notice The address of the `weth` token.
  IWETH9 public immutable weth;

  /// @notice The address of the Aave v2 LendingPool contract. This is the contract that all `withdraw` and `repay` transactions go through.
  ILendingPool public immutable aaveV2LendingPool;

  /// @notice Address to send swept tokens to, if for any reason they remain locked in this contract.
  address payable public immutable sweepee;

  /// @notice A reentrancy guard.
  uint256 public inMigration;

  /**
   * @notice Construct a new CometMigratorV2
   * @param comet_ The Comet Ethereum mainnet USDC contract.
   * @param baseToken_ The base token of the Compound III market (e.g. `USDC`).
   * @param cETH_ The address of the `cETH` token.
   * @param weth_ The address of the `WETH9` token.
   * @param aaveV2LendingPool_ The address of the Aave v2 LendingPool contract. This is the contract that all `withdraw` and `repay` transactions go through.
   * @param uniswapLiquidityPool_ The Uniswap pool used by this contract to source liquidity (i.e. flash loans).
   * @param swapRouter_ The Uniswap router for facilitating token swaps.
   * @param sweepee_ Sweep excess tokens to this address.
   **/
  constructor(
    Comet comet_,
    IERC20NonStandard baseToken_,
    CTokenLike cETH_,
    IWETH9 weth_,
    ILendingPool aaveV2LendingPool_,
    IUniswapV3Pool uniswapLiquidityPool_,
    ISwapRouter swapRouter_,
    address payable sweepee_
  ) {
    // **WRITE IMMUTABLE** `comet = comet_`
    comet = comet_;

    // **WRITE IMMUTABLE** `baseToken = baseToken_`
    baseToken = baseToken_;

    // **WRITE IMMUTABLE** `cETH = cETH_`
    cETH = cETH_;

    // **WRITE IMMUTABLE** `weth = weth_`
    weth = weth_;

    // **WRITE IMMUTABLE** `aaveV2LendingPool = aaveV2LendingPool_`
    aaveV2LendingPool = aaveV2LendingPool_;

    // **WRITE IMMUTABLE** `uniswapLiquidityPool = uniswapLiquidityPool_`
    uniswapLiquidityPool = uniswapLiquidityPool_;

    // **WRITE IMMUTABLE** `isUniswapLiquidityPoolToken0 = uniswapLiquidityPool.token0() == baseToken`
    isUniswapLiquidityPoolToken0 = uniswapLiquidityPool.token0() == address(baseToken);

    // **REQUIRE** `isUniswapLiquidityPoolToken0 || uniswapLiquidityPool.token1() == baseToken`
    if (!isUniswapLiquidityPoolToken0 && uniswapLiquidityPool.token1() != address(baseToken)) {
      revert InvalidConfiguration(0);
    }

    // **WRITE IMMUTABLE** `swapRouter = swapRouter_`
    swapRouter = swapRouter_;

    // **WRITE IMMUTABLE** `sweepee = sweepee_`
    sweepee = sweepee_;

    // **CALL** `baseToken.approve(address(swapRouter), type(uint256).max)`
    baseToken.approve(address(swapRouter), type(uint256).max);
  }

  /**
   * @notice This is the core function of this contract, migrating a position from Compound II to Compound III. We use a flash loan from Uniswap to provide liquidity to move the position.
   * @param compoundV2Position Structure containing the user’s Compound II collateral and borrow positions to migrate to Compound III. See notes below.
   * @param aaveV2Position Structure containing the user’s Aave v2 collateral and borrow positions to migrate to Compound III. See notes below.
   * @param flashAmount Amount of base asset to borrow from the Uniswap flash loan to facilitate the migration. See notes below.
   * @dev **N.B.** Collateral requirements may be different in Compound II and Compound III. This may lead to a migration failing or being less collateralized after the migration. There are fees associated with the flash loan, which may affect position or cause migration to fail.
   * @dev Note: each `collateral` market must be supported in Compound III.
   * @dev Note: `collateral` amounts of 0 are strictly ignored. Collateral amounts of max uint256 are set to the user's current balance.
   * @dev Note: `flashAmount` is provided by the user as a hint to the Migrator to know the maximum expected cost (in terms of the base asset) of the migration. If `flashAmount` is less than the total amount needed to migrate the user’s positions, the transaction will revert.
   **/
  function migrate(CompoundV2Position calldata compoundV2Position, AaveV2Position calldata aaveV2Position, uint256 flashAmount) external {
    // **REQUIRE** `inMigration == 0`
    if (inMigration != 0) {
      revert Reentrancy(0);
    }

    // **STORE** `inMigration += 1`
    inMigration += 1;

    // **BIND** `user = msg.sender`
    address user = msg.sender;

    // **REQUIRE** `compoundV2Position.borrows.length == compoundV2Position.swaps.length`
    if (compoundV2Position.borrows.length != compoundV2Position.swaps.length) {
      revert InvalidInputs(0);
    }

    // **REQUIRE** `aaveV2Position.borrows.length == aaveV2Position.swaps.length`
    if (aaveV2Position.borrows.length != aaveV2Position.swaps.length) {
      revert InvalidInputs(1);
    }

    // **BIND** `data = abi.encode(MigrationCallbackData{user, flashAmount, compoundV2Position, aaveV2Position, makerPositions})`
    bytes memory data = abi.encode(MigrationCallbackData({
      user: user,
      flashAmount: flashAmount,
      compoundV2Position: compoundV2Position,
      aaveV2Position: aaveV2Position
    }));

    // **CALL** `uniswapLiquidityPool.flash(address(this), isUniswapLiquidityPoolToken0 ? flashAmount : 0, isUniswapLiquidityPoolToken0 ? 0 : flashAmount, data)`
    uniswapLiquidityPool.flash(address(this), isUniswapLiquidityPoolToken0 ? flashAmount : 0, isUniswapLiquidityPoolToken0 ? 0 : flashAmount, data);

    // **STORE** `inMigration -= 1`
    inMigration -= 1;
  }

  /**
   * @notice This function handles a callback from the Uniswap Liquidity Pool after it has sent this contract the requested tokens. We are responsible for repaying those tokens, with a fee, before we return from this function call.
   * @param fee0 The fee for borrowing token0 from pool.
   * @param fee1 The fee for borrowing token1 from pool.
   * @param data The data encoded above, which is the ABI-encoding of `MigrationCallbackData`.
   **/
  function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
    // **REQUIRE** `inMigration == 1`
    if (inMigration != 1) {
      revert Reentrancy(1);
    }

    // **REQUIRE** `msg.sender == uniswapLiquidityPool`
    if (msg.sender != address(uniswapLiquidityPool)) {
      revert InvalidCallback(0);
    }

    // **BIND** `MigrationCallbackData{user, flashAmount, compoundV2Position, aaveV2Position, cdpPositions} = abi.decode(data, (MigrationCallbackData))`
    MigrationCallbackData memory migrationData = abi.decode(data, (MigrationCallbackData));

    // **BIND** `flashAmountWithFee = flashAmount + isUniswapLiquidityPoolToken0 ? fee0 : fee1`
    uint256 flashAmountWithFee = migrationData.flashAmount + ( isUniswapLiquidityPoolToken0 ? fee0 : fee1 );

    // **EXEC** `migrateCompoundV2Position(user, compoundV2Position)`
    migrateCompoundV2Position(migrationData.user, migrationData.compoundV2Position);

    // **EXEC** `migrateAaveV2Position(user, aaveV2Position)`
    migrateAaveV2Position(migrationData.user, migrationData.aaveV2Position);

    // **WHEN** `baseToken.balanceOf(address(this)) < flashAmountWithFee`:
    uint256 baseTokenBalance = baseToken.balanceOf(address(this));
    if (baseTokenBalance < flashAmountWithFee) {
      // **CALL** `comet.withdrawFrom(user, address(this), baseToken, flashAmountWithFee - baseToken.balanceOf(address(this)))`
      comet.withdrawFrom(migrationData.user, address(this), address(baseToken), flashAmountWithFee - baseTokenBalance);
    }

    // **CALL** `baseToken.transfer(address(uniswapLiquidityPool), flashAmountWithFee)`
    if (!doTransferOut(baseToken, address(uniswapLiquidityPool), flashAmountWithFee)) {
      revert ERC20TransferFailure(0);
    }

    // **EMIT** `Migrated(user, compoundV2Position, aaveV2Position, cdpPositions, flashAmount, flashAmountWithFee)`
    emit Migrated(migrationData.user, migrationData.compoundV2Position, migrationData.aaveV2Position, migrationData.flashAmount, flashAmountWithFee);
  }

  /**
   * @notice This internal helper function repays the user’s borrow positions on Compound II (executing swaps first if necessary) before migrating their collateral over to Compound III.
   * @param user Alias for the `msg.sender` of the original `migrate` call.
   * @param position Structure containing the user’s Compound II collateral and borrow positions to migrate to Compound III.
   **/
  function migrateCompoundV2Position(address user, CompoundV2Position memory position) internal {
    // **FOREACH** `(cToken, borrowAmount): CompoundV2Borrow, swap: Swap` in `position`:
    for (uint i = 0; i < position.borrows.length; i++) {
      CompoundV2Borrow memory borrow = position.borrows[i];

      uint256 repayAmount;
      // **WHEN** `borrowAmount == type(uint256).max)`:
      if (borrow.amount == type(uint256).max) {
        // **BIND READ** `repayAmount = cToken.borrowBalanceCurrent(user)`
        repayAmount = borrow.cToken.borrowBalanceCurrent(user);
      } else {
        // **BIND** `repayAmount = borrowAmount`
        repayAmount = borrow.amount;
      }

      // **WHEN** `swap.path.length > 0`:
      if (position.swaps[i].path.length > 0) {
        // **CALL** `ISwapRouter.exactOutput(ExactOutputParams({path: swap.path, recipient: address(this), amountOut: repayAmount, amountInMaximum: swap.amountInMaximum})`
        uint256 amountIn = swapRouter.exactOutput(
          ISwapRouter.ExactOutputParams({
              path: position.swaps[i].path,
              recipient: address(this),
              amountOut: repayAmount,
              amountInMaximum: position.swaps[i].amountInMaximum,
              deadline: block.timestamp
          })
        );
      }

      // **WHEN** `cToken == cETH`
      if (borrow.cToken == cETH) {
        CEther cToken = CEther(address(borrow.cToken));

        // **CALL** `weth.withdraw(repayAmount)`
        weth.withdraw(repayAmount);

        // **CALL** `cToken.repayBorrowBehalf{value: repayAmount}(user)
        cToken.repayBorrowBehalf{ value: repayAmount }(user);
      } else {
        CErc20 cToken = CErc20(address(borrow.cToken));

        // **CALL** `cToken.underlying().approve(address(cToken), repayAmount)`
        IERC20NonStandard(cToken.underlying()).approve(address(borrow.cToken), repayAmount);

        // **CALL** `cToken.repayBorrowBehalf(user, repayAmount)`
        uint256 err = cToken.repayBorrowBehalf(user, repayAmount);
        if (err != 0) {
          revert CompoundV2Error(0, err);
        }
      }
    }

    // **FOREACH** `(cToken, amount): CompoundV2Collateral` in `position.collateral`:
    for (uint i = 0; i < position.collateral.length; i++) {
      CompoundV2Collateral memory collateral = position.collateral[i];

      // **BIND** `cTokenAmount = amount == type(uint256).max ? cToken.balanceOf(user) : amount)`
      uint256 cTokenAmount = collateral.amount == type(uint256).max ? collateral.cToken.balanceOf(user) : collateral.amount;

      // **CALL** `cToken.transferFrom(user, address(this), cTokenAmount)`
      bool transferSuccess = collateral.cToken.transferFrom(
        user,
        address(this),
        cTokenAmount
      );
      if (!transferSuccess) {
        revert CTokenTransferFailure();
      }

      // **CALL** `cToken.redeem(cTokenAmount)`
      uint256 err = collateral.cToken.redeem(cTokenAmount);
      if (err != 0) {
        revert CompoundV2Error(1 + i, err);
      }

      // Note: Safe to use `exchangeRateStored` since `accrue` is already called in `redeem`
      // **BIND** `underlyingCollateralAmount = collateral.cToken.exchangeRateStored() * cTokenAmount / 1e18`
      uint256 underlyingCollateralAmount = collateral.cToken.exchangeRateStored() * cTokenAmount / 1e18;

      IERC20NonStandard underlying;

      // **WHEN** `cToken == cETH`:
      if (collateral.cToken == cETH) {
        // **CALL** `weth.deposit{value: underlyingCollateralAmount}()`
        weth.deposit{value: underlyingCollateralAmount}();

        // **BIND** `underlying = weth`
        underlying = weth;
      } else {
        // **BIND** `underlying = cToken.underlying()`
        underlying = IERC20NonStandard(CErc20(address(collateral.cToken)).underlying());
      }

      // **CALL** `underlying.approve(address(comet), underlyingCollateralAmount)`
      underlying.approve(address(comet), underlyingCollateralAmount);

      // **CALL** `comet.supplyTo(user, underlying, underlyingCollateralAmount)`
      comet.supplyTo(
        user,
        address(underlying),
        underlyingCollateralAmount
      );
    }
  }

  /**
   * @notice This internal helper function repays the user’s borrow positions on Aave v2 (executing swaps first if necessary) before migrating their collateral over to Compound III.
   * @param user Alias for the `msg.sender` of the original `migrate` call.
   * @param position Structure containing the user’s Aave v2 collateral and borrow positions to migrate to Compound III.
   **/
  function migrateAaveV2Position(address user, AaveV2Position memory position) internal {
    // **FOREACH** `(aDebtToken, borrowAmount): AaveV2Borrow, swap: Swap` in `position`:
    for (uint i = 0; i < position.borrows.length; i++) {
      AaveV2Borrow memory borrow = position.borrows[i];
      uint256 repayAmount;
      //  **WHEN** `borrowAmount == type(uint256).max)`:
      if (borrow.amount == type(uint256).max) {
        // **BIND READ** `repayAmount = aDebtToken.balanceOf(user)`
        repayAmount = borrow.aDebtToken.balanceOf(user);
      } else {
        //  **BIND** `repayAmount = borrowAmount`
        repayAmount = borrow.amount;
      }
      // **WHEN** `swap.path.length > 0`:
      if (position.swaps[i].path.length > 0) {
        // **CALL** `ISwapRouter.exactOutput(ExactOutputParams({path: swap.path, recipient: address(this), amountOut: repayAmount, amountInMaximum: swap.amountInMaximum})`
        uint256 amountIn = swapRouter.exactOutput(
          ISwapRouter.ExactOutputParams({
              path: position.swaps[i].path,
              recipient: address(this),
              amountOut: repayAmount,
              amountInMaximum: position.swaps[i].amountInMaximum,
              deadline: block.timestamp
          })
        );
      }

      // **BIND READ** `underlyingDebt = aDebtToken.UNDERLYING_ASSET_ADDRESS()`
      IERC20NonStandard underlyingDebt = IERC20NonStandard(borrow.aDebtToken.UNDERLYING_ASSET_ADDRESS());

      // **BIND READ** `rateMode = aDebtToken.DEBT_TOKEN_REVISION()`
      uint256 rateMode = borrow.aDebtToken.DEBT_TOKEN_REVISION();

      // **CALL** `underlyingDebt.approve(address(aaveV2LendingPool), repayAmount)`
      underlyingDebt.approve(address(aaveV2LendingPool), repayAmount);

      // **CALL** `aaveV2LendingPool.repay(underlyingDebt, repayAmount, rateMode, user)`
      aaveV2LendingPool.repay(address(underlyingDebt), repayAmount, rateMode, user);
    }

    // **FOREACH** `(aToken, amount): AaveV2Collateral` in `position.collateral`:
    for (uint i = 0; i < position.collateral.length; i++) {
      AaveV2Collateral memory collateral = position.collateral[i];

      // **BIND** `aTokenAmount = amount == type(uint256).max ? aToken.balanceOf(user) : amount)`
      uint256 aTokenAmount = collateral.amount == type(uint256).max ? collateral.aToken.balanceOf(user) : collateral.amount;

      // **CALL** `aToken.transferFrom(user, address(this), aTokenAmount)`
      collateral.aToken.transferFrom(
        user,
        address(this),
        aTokenAmount
      );

      // **BIND READ** `underlyingCollateral = aToken.UNDERLYING_ASSET_ADDRESS()`
      IERC20NonStandard underlyingCollateral = IERC20NonStandard(collateral.aToken.UNDERLYING_ASSET_ADDRESS());

      // **CALL** `aaveV2LendingPool.withdraw(underlyingCollateral, aTokenAmount, address(this))`
      aaveV2LendingPool.withdraw(address(underlyingCollateral), aTokenAmount, address(this));

      // **CALL** `underlyingCollateral.approve(address(comet), aTokenAmount)`
      underlyingCollateral.approve(address(comet), aTokenAmount);

      // **CALL** `comet.supplyTo(user, underlyingCollateral, aTokenAmount)`
      comet.supplyTo(
        user,
        address(underlyingCollateral),
        aTokenAmount
      );
    }
  }

  /**
    * @notice Similar to ERC-20 transfer, except it also properly handles `transfer` from non-standard ERC-20 tokens.
    * @param asset The ERC-20 token to transfer out.
    * @param to The recipient of the token transfer.
    * @param amount The amount of the token to transfer.
    * @return Boolean indicating the success of the transfer.
    * @dev Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value. See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    **/
  function doTransferOut(IERC20NonStandard asset, address to, uint amount) internal returns (bool) {
      asset.transfer(to, amount);

      bool success;
      assembly {
          switch returndatasize()
              case 0 {                      // This is a non-standard ERC-20
                  success := not(0)          // set success to true
              }
              case 32 {                     // This is a compliant ERC-20
                  returndatacopy(0, 0, 32)
                  success := mload(0)        // Set `success = returndata` of override external call
              }
              default {                     // This is an excessively non-compliant ERC-20, revert.
                  revert(0, 0)
              }
      }
      return success;
  }

  /**
   * @notice Sends any tokens in this contract to the sweepee address. This contract should never hold tokens, so this is just to fix any anomalistic situations where tokens end up locked in the contract.
   * @param token The token to sweep
   **/
  function sweep(IERC20NonStandard token) external {
    // **REQUIRE** `inMigration == 0`
    if (inMigration != 0) {
      revert Reentrancy(2);
    }

    // **WHEN** `token == 0x0000000000000000000000000000000000000000`:
    if (token == IERC20NonStandard(0x0000000000000000000000000000000000000000)) {
      // **EXEC** `sweepee.send(address(this).balance)`
      uint256 amount = address(this).balance;
      if (!sweepee.send(amount)) {
        revert SweepFailure(0);
      }

      // **EMIT** `Sweep(msg.sender, sweepee, address(0), address(this).balance)`
      emit Sweep(msg.sender, sweepee, address(0), amount);
    } else {
      // **CALL** `token.transfer(sweepee, token.balanceOf(address(this)))`
      uint256 amount = token.balanceOf(address(this));
      if (!doTransferOut(token, sweepee, amount)) {
        revert SweepFailure(1);
      }

      // **EMIT** `Sweep(msg.sender, sweepee, address(token), token.balanceOf(address(this)))`
      emit Sweep(msg.sender, sweepee, address(token), amount);
    }
  }

  receive() external payable {
    // NO-OP
  }
}