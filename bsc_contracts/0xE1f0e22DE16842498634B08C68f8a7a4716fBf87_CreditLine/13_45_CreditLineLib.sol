// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ICreditLineStorage} from './interfaces/ICreditLineStorage.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ICreditLineController} from './interfaces/ICreditLineController.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {
  FixedPoint
} from '../../../@uma/core/contracts/common/implementation/FixedPoint.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {CreditLine} from './CreditLine.sol';

library CreditLineLib {
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for IStandardERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using CreditLineLib for ICreditLineStorage.PositionData;
  using CreditLineLib for ICreditLineStorage.PositionManagerData;
  using CreditLineLib for ICreditLineStorage.FeeStatus;
  using CreditLineLib for FixedPoint.Unsigned;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );

  event ClaimFee(
    address indexed claimer,
    uint256 feeAmount,
    uint256 totalRemainingFees
  );

  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(
    address indexed caller,
    uint256 settlementPrice,
    uint256 shutdownTimestamp
  );
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  //----------------------------------------
  // External functions
  //----------------------------------------

  function initialize(
    ICreditLineStorage.PositionManagerData storage self,
    ISynthereumFinder _finder,
    IStandardERC20 _collateralToken,
    IMintableBurnableERC20 _tokenCurrency,
    bytes32 _priceIdentifier,
    FixedPoint.Unsigned memory _minSponsorTokens,
    address _excessTokenBeneficiary,
    uint8 _version
  ) external {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        _finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );

    require(
      priceFeed.isPriceSupported(_priceIdentifier),
      'Price identifier not supported'
    );
    require(
      _collateralToken.decimals() <= 18,
      'Collateral has more than 18 decimals'
    );
    require(
      _tokenCurrency.decimals() == 18,
      'Synthetic token has more or less than 18 decimals'
    );
    self.priceIdentifier = _priceIdentifier;
    self.synthereumFinder = _finder;
    self.collateralToken = _collateralToken;
    self.tokenCurrency = _tokenCurrency;
    self.minSponsorTokens = _minSponsorTokens;
    self.excessTokenBeneficiary = _excessTokenBeneficiary;
    self.version = _version;
  }

  function depositTo(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    address sponsor,
    address msgSender
  ) external {
    require(collateralAmount.rawValue > 0, 'Invalid collateral amount');

    // Increase the position and global collateral balance by collateral amount.
    positionData._incrementCollateralBalances(
      globalPositionData,
      collateralAmount
    );

    emit Deposit(sponsor, collateralAmount.rawValue);

    positionManagerData.collateralToken.safeTransferFrom(
      msgSender,
      address(this),
      collateralAmount.rawValue
    );
  }

  function withdraw(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    address msgSender
  ) external returns (FixedPoint.Unsigned memory) {
    require(collateralAmount.rawValue > 0, 'Invalid collateral amount');

    // Decrement the sponsor's collateral and global collateral amounts.
    // Reverts if the resulting position is not properly collateralized
    _decrementCollateralBalancesCheckCR(
      positionData,
      globalPositionData,
      positionManagerData,
      collateralAmount
    );

    emit Withdrawal(msgSender, collateralAmount.rawValue);

    // Move collateral currency from contract to sender.
    positionManagerData.collateralToken.safeTransfer(
      msgSender,
      collateralAmount.rawValue
    );

    return collateralAmount;
  }

  function create(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens,
    ICreditLineStorage.FeeStatus storage feeStatus,
    address msgSender
  ) external returns (FixedPoint.Unsigned memory feeAmount) {
    // Update fees status - percentage is retrieved from Credit Line Controller
    FixedPoint.Unsigned memory priceRate = _getOraclePrice(positionManagerData);
    uint8 collateralDecimals =
      getCollateralDecimals(positionManagerData.collateralToken);
    feeAmount = calculateCollateralAmount(
      numTokens,
      priceRate,
      collateralDecimals
    )
      .mul(
      FixedPoint.Unsigned(positionManagerData._getFeeInfo().feePercentage)
    );
    positionManagerData.updateFees(feeStatus, feeAmount);

    if (positionData.tokensOutstanding.isEqual(0)) {
      require(
        _checkCollateralization(
          positionManagerData,
          collateralAmount.sub(feeAmount),
          numTokens,
          priceRate,
          collateralDecimals
        ),
        'Insufficient Collateral'
      );
      require(
        numTokens.isGreaterThanOrEqual(positionManagerData.minSponsorTokens),
        'Below minimum sponsor position'
      );
      emit NewSponsor(msgSender);
    } else {
      require(
        _checkCollateralization(
          positionManagerData,
          positionData.rawCollateral.add(collateralAmount).sub(feeAmount),
          positionData.tokensOutstanding.add(numTokens),
          priceRate,
          collateralDecimals
        ),
        'Insufficient Collateral'
      );
    }

    // Increase or decrease the position and global collateral balance by collateral amount or fee amount.
    collateralAmount.isGreaterThanOrEqual(feeAmount)
      ? positionData._incrementCollateralBalances(
        globalPositionData,
        collateralAmount.sub(feeAmount)
      )
      : positionData._decrementCollateralBalances(
        globalPositionData,
        feeAmount.sub(collateralAmount)
      );

    // Add the number of tokens created to the position's outstanding tokens and global.
    positionData.tokensOutstanding = positionData.tokensOutstanding.add(
      numTokens
    );

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .add(numTokens);

    checkMintLimit(globalPositionData, positionManagerData);

    if (collateralAmount.rawValue > 0) {
      // pull collateral
      IERC20 collateralCurrency = positionManagerData.collateralToken;

      // Transfer tokens into the contract from caller
      collateralCurrency.safeTransferFrom(
        msgSender,
        address(this),
        (collateralAmount).rawValue
      );
    }

    // mint corresponding synthetic tokens to the caller's address.
    positionManagerData.tokenCurrency.mint(msgSender, numTokens.rawValue);

    emit PositionCreated(
      msgSender,
      collateralAmount.rawValue,
      numTokens.rawValue,
      feeAmount.rawValue
    );
  }

  function redeem(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    address sponsor
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(
      numTokens.isLessThanOrEqual(positionData.tokensOutstanding),
      'Invalid token amount'
    );

    amountWithdrawn = positionData.rawCollateral.mul(numTokens).div(
      positionData.tokensOutstanding
    );

    // If redemption returns all tokens the sponsor has then we can delete their position. Else, downsize.
    if (positionData.tokensOutstanding.isEqual(numTokens)) {
      positionData._deleteSponsorPosition(globalPositionData, sponsor);
    } else {
      // Decrement the sponsor's collateral and global collateral amounts.
      positionData._decrementCollateralBalances(
        globalPositionData,
        amountWithdrawn
      );

      // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
      FixedPoint.Unsigned memory newTokenCount =
        positionData.tokensOutstanding.sub(numTokens);
      require(
        newTokenCount.isGreaterThanOrEqual(
          positionManagerData.minSponsorTokens
        ),
        'Below minimum sponsor position'
      );
      positionData.tokensOutstanding = newTokenCount;
      // Update the totalTokensOutstanding after redemption.
      globalPositionData.totalTokensOutstanding = globalPositionData
        .totalTokensOutstanding
        .sub(numTokens);
    }

    // transfer collateral to user
    IERC20 collateralCurrency = positionManagerData.collateralToken;

    {
      collateralCurrency.safeTransfer(sponsor, amountWithdrawn.rawValue);

      // Pull and burn callers synthetic tokens.
      positionManagerData.tokenCurrency.safeTransferFrom(
        sponsor,
        address(this),
        numTokens.rawValue
      );
      positionManagerData.tokenCurrency.burn(numTokens.rawValue);
    }

    emit Redeem(sponsor, amountWithdrawn.rawValue, numTokens.rawValue);
  }

  function repay(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    address msgSender
  ) external {
    require(
      numTokens.isLessThanOrEqual(positionData.tokensOutstanding),
      'Invalid token amount'
    );

    // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
    FixedPoint.Unsigned memory newTokenCount =
      positionData.tokensOutstanding.sub(numTokens);
    require(
      newTokenCount.isGreaterThanOrEqual(positionManagerData.minSponsorTokens),
      'Below minimum sponsor position'
    );

    // update position
    positionData.tokensOutstanding = newTokenCount;

    // Update the totalTokensOutstanding after redemption.
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(numTokens);

    // Transfer the tokens back from the sponsor and burn them.
    positionManagerData.tokenCurrency.safeTransferFrom(
      msgSender,
      address(this),
      numTokens.rawValue
    );
    positionManagerData.tokenCurrency.burn(numTokens.rawValue);

    emit Repay(msgSender, numTokens.rawValue, newTokenCount.rawValue);
  }

  function liquidate(
    ICreditLineStorage.PositionData storage positionToLiquidate,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    FixedPoint.Unsigned calldata numSynthTokens,
    address msgSender
  )
    external
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // to avoid stack too deep
    ICreditLineStorage.ExecuteLiquidationData memory executeLiquidationData;
    uint8 collateralDecimals =
      getCollateralDecimals(positionManagerData.collateralToken);

    FixedPoint.Unsigned memory priceRate = _getOraclePrice(positionManagerData);

    // make sure position is undercollateralised
    require(
      !positionManagerData._checkCollateralization(
        positionToLiquidate.rawCollateral,
        positionToLiquidate.tokensOutstanding,
        priceRate,
        collateralDecimals
      ),
      'Position is properly collateralised'
    );

    // calculate tokens to liquidate
    executeLiquidationData.tokensToLiquidate.rawValue = positionToLiquidate
      .tokensOutstanding
      .isGreaterThan(numSynthTokens)
      ? numSynthTokens.rawValue
      : positionToLiquidate.tokensOutstanding.rawValue;

    // calculate collateral value of those tokens
    executeLiquidationData
      .collateralValueLiquidatedTokens = calculateCollateralAmount(
      executeLiquidationData.tokensToLiquidate,
      priceRate,
      collateralDecimals
    );

    // calculate proportion of collateral liquidated from position
    executeLiquidationData.collateralLiquidated = executeLiquidationData
      .tokensToLiquidate
      .div(positionToLiquidate.tokensOutstanding)
      .mul(positionToLiquidate.rawCollateral);

    // compute final liquidation outcome
    if (
      executeLiquidationData.collateralLiquidated.isGreaterThan(
        executeLiquidationData.collateralValueLiquidatedTokens
      )
    ) {
      // position is still capitalised - liquidator profits
      executeLiquidationData.liquidatorReward = (
        executeLiquidationData.collateralLiquidated.sub(
          executeLiquidationData.collateralValueLiquidatedTokens
        )
      )
        .mul(positionManagerData._getLiquidationReward());
      executeLiquidationData.collateralLiquidated = executeLiquidationData
        .collateralValueLiquidatedTokens
        .add(executeLiquidationData.liquidatorReward);
    }

    // reduce position
    positionToLiquidate._reducePosition(
      globalPositionData,
      executeLiquidationData.tokensToLiquidate,
      executeLiquidationData.collateralLiquidated
    );

    // transfer tokens from liquidator to here and burn them
    _burnLiquidatedTokens(
      positionManagerData,
      msgSender,
      executeLiquidationData.tokensToLiquidate.rawValue
    );

    // pay sender with collateral unlocked + rewards
    positionManagerData.collateralToken.safeTransfer(
      msgSender,
      executeLiquidationData.collateralLiquidated.rawValue
    );

    // return values
    return (
      executeLiquidationData.collateralLiquidated.rawValue,
      executeLiquidationData.tokensToLiquidate.rawValue,
      executeLiquidationData.liquidatorReward.rawValue
    );
  }

  function emergencyShutdown(
    ICreditLineStorage.PositionManagerData storage self
  ) external returns (uint256 timestamp, uint256 price) {
    require(
      msg.sender ==
        self.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.Manager
        ),
      'Caller must be a Synthereum manager'
    );

    timestamp = block.timestamp;
    FixedPoint.Unsigned memory _price = self._getOraclePrice();

    // store timestamp and last price
    self.emergencyShutdownTimestamp = timestamp;
    self.emergencyShutdownPrice = _price;

    price = _price.rawValue;

    emit EmergencyShutdown(msg.sender, price, timestamp);
  }

  function settleEmergencyShutdown(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    address msgSender
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    // copy value
    FixedPoint.Unsigned memory emergencyShutdownPrice =
      positionManagerData.emergencyShutdownPrice;
    IMintableBurnableERC20 tokenCurrency = positionManagerData.tokenCurrency;
    FixedPoint.Unsigned memory rawCollateral = positionData.rawCollateral;
    FixedPoint.Unsigned memory totalCollateral =
      globalPositionData.rawTotalPositionCollateral;

    // Get caller's tokens balance
    FixedPoint.Unsigned memory tokensToRedeem =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msgSender));

    // calculate amount of underlying collateral entitled to them, with oracle emergency price
    FixedPoint.Unsigned memory totalRedeemableCollateral =
      tokensToRedeem.mul(emergencyShutdownPrice);

    // If the caller is a sponsor with outstanding collateral they are also entitled to their excess collateral after their debt.
    if (rawCollateral.rawValue > 0) {
      // Calculate the underlying entitled to a token sponsor. This is collateral - debt
      FixedPoint.Unsigned memory tokenDebtValueInCollateral =
        positionData.tokensOutstanding.mul(emergencyShutdownPrice);

      // accrued to withdrawable collateral eventual excess collateral after debt
      if (tokenDebtValueInCollateral.isLessThan(rawCollateral)) {
        totalRedeemableCollateral = totalRedeemableCollateral.add(
          rawCollateral.sub(tokenDebtValueInCollateral)
        );
      }

      CreditLine(address(this)).deleteSponsorPosition(msgSender);
      emit EndedSponsorPosition(msgSender);
    }

    // Take the min of the remaining collateral and the collateral "owed". If the contract is undercapitalized,
    // the caller will get as much collateral as the contract can pay out.
    amountWithdrawn = FixedPoint.min(
      totalCollateral,
      totalRedeemableCollateral
    );

    // Decrement total contract collateral and outstanding debt.
    globalPositionData.rawTotalPositionCollateral = totalCollateral.sub(
      amountWithdrawn
    );
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToRedeem);

    emit SettleEmergencyShutdown(
      msgSender,
      amountWithdrawn.rawValue,
      tokensToRedeem.rawValue
    );

    // Transfer tokens & collateral and burn the redeemed tokens.
    positionManagerData.collateralToken.safeTransfer(
      msgSender,
      amountWithdrawn.rawValue
    );
    tokenCurrency.safeTransferFrom(
      msgSender,
      address(this),
      tokensToRedeem.rawValue
    );
    tokenCurrency.burn(tokensToRedeem.rawValue);
  }

  /**
   * @notice Withdraw fees gained by the sender
   * @param self Data type the library is attached to
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @return feeClaimed Amount of fee claimed
   */
  function claimFee(
    ICreditLineStorage.PositionManagerData storage self,
    ICreditLineStorage.FeeStatus storage feeStatus,
    address msgSender
  ) external returns (uint256 feeClaimed) {
    // Fee to claim
    FixedPoint.Unsigned memory _feeClaimed = feeStatus.feeGained[msgSender];

    // Check that fee is available
    require(_feeClaimed.rawValue > 0, 'No fee to claim');

    // Update fee status
    delete feeStatus.feeGained[msgSender];

    FixedPoint.Unsigned memory _totalRemainingFees =
      feeStatus.totalFeeAmount.sub(_feeClaimed);

    feeStatus.totalFeeAmount = _totalRemainingFees;

    // Transfer amount to the sender
    feeClaimed = _feeClaimed.rawValue;

    self.collateralToken.safeTransfer(msgSender, _feeClaimed.rawValue);

    emit ClaimFee(msgSender, feeClaimed, _totalRemainingFees.rawValue);
  }

  function trimExcess(
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.FeeStatus storage feeStatus,
    IERC20 token
  ) external returns (FixedPoint.Unsigned memory amount) {
    FixedPoint.Unsigned memory balance =
      FixedPoint.Unsigned(token.balanceOf(address(this)));
    if (address(token) == address(positionManagerData.collateralToken)) {
      FixedPoint.Unsigned memory rawTotalPositionCollateral =
        globalPositionData.rawTotalPositionCollateral;
      FixedPoint.Unsigned memory totalFeeAmount = feeStatus.totalFeeAmount;
      // If it is the collateral currency, send only the amount that the contract is not tracking (ie minus fees and positions)
      balance.isGreaterThan(rawTotalPositionCollateral.add(totalFeeAmount))
        ? amount = balance.sub(rawTotalPositionCollateral).sub(totalFeeAmount)
        : amount = FixedPoint.Unsigned(0);
    } else {
      // If it's not the collateral currency, send the entire balance.
      amount = balance;
    }
    token.safeTransfer(
      positionManagerData.excessTokenBeneficiary,
      amount.rawValue
    );
  }

  /**
   * @notice Returns if position is overcollateralized and thepercentage of coverage of the collateral according to the last price
   * @param self Data type the library is attached to
   * @param positionData Position of the LP
   * @return True if position is overcollaterlized, otherwise false + percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage(
    ICreditLineStorage.PositionManagerData storage self,
    ICreditLineStorage.PositionData storage positionData
  ) external view returns (bool, uint256) {
    FixedPoint.Unsigned memory priceRate = _getOraclePrice(self);
    uint8 collateralDecimals = getCollateralDecimals(self.collateralToken);
    FixedPoint.Unsigned memory positionCollateral = positionData.rawCollateral;
    FixedPoint.Unsigned memory positionTokens = positionData.tokensOutstanding;
    bool _isOverCollateralised =
      _checkCollateralization(
        self,
        positionCollateral,
        positionTokens,
        priceRate,
        collateralDecimals
      );

    FixedPoint.Unsigned memory collateralRequirementPrc =
      self._getCollateralRequirement();

    FixedPoint.Unsigned memory overCollateralValue =
      getOverCollateralizationLimit(
        calculateCollateralAmount(
          positionData.tokensOutstanding,
          priceRate,
          collateralDecimals
        ),
        collateralRequirementPrc
      );

    FixedPoint.Unsigned memory coverageRatio =
      positionCollateral.div(overCollateralValue);

    FixedPoint.Unsigned memory _collateralCoverage =
      collateralRequirementPrc.mul(coverageRatio);

    return (_isOverCollateralised, _collateralCoverage.rawValue);
  }

  function liquidationPrice(
    ICreditLineStorage.PositionManagerData storage self,
    ICreditLineStorage.PositionData storage positionData
  ) external view returns (uint256 liqPrice) {
    // liquidationPrice occurs when totalCollateral is entirely occupied in the position value * collateral requirement
    // positionCollateral = positionTokensOut * liqPrice * collRequirement
    uint8 collateralDecimals = getCollateralDecimals(self.collateralToken);
    liqPrice = positionData
      .rawCollateral
      .div(self._getCollateralRequirement())
      .mul(10**(18 - collateralDecimals))
      .div(positionData.tokensOutstanding)
      .rawValue;
  }

  //Calls to the CreditLine controller
  function capMintAmount(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) external view returns (FixedPoint.Unsigned memory capMint) {
    capMint = positionManagerData._getCapMintAmount();
  }

  function liquidationRewardPercentage(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) external view returns (FixedPoint.Unsigned memory liqRewardPercentage) {
    liqRewardPercentage = positionManagerData._getLiquidationReward();
  }

  function feeInfo(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) external view returns (ICreditLineStorage.Fee memory fee) {
    fee = positionManagerData._getFeeInfo();
  }

  function collateralRequirement(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) external view returns (FixedPoint.Unsigned memory) {
    return positionManagerData._getCollateralRequirement();
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------
  /**
   * @notice Update fee gained by the fee recipients
   * @param feeStatus Actual status of fee gained to be withdrawn
   * @param feeAmount Collateral fee charged
   */
  function updateFees(
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    ICreditLineStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned memory feeAmount
  ) internal {
    FixedPoint.Unsigned memory feeCharged;

    ICreditLineStorage.Fee memory feeStruct = positionManagerData._getFeeInfo();
    address[] memory feeRecipients = feeStruct.feeRecipients;
    uint32[] memory feeProportions = feeStruct.feeProportions;
    uint256 totalFeeProportions = feeStruct.totalFeeProportions;
    uint256 numberOfRecipients = feeRecipients.length;
    mapping(address => FixedPoint.Unsigned) storage feeGained =
      feeStatus.feeGained;

    for (uint256 i = 0; i < numberOfRecipients - 1; i++) {
      address feeRecipient = feeRecipients[i];
      FixedPoint.Unsigned memory feeReceived =
        FixedPoint.Unsigned(
          (feeAmount.rawValue * feeProportions[i]) / totalFeeProportions
        );
      feeGained[feeRecipient] = feeGained[feeRecipient].add(feeReceived);
      feeCharged = feeCharged.add(feeReceived);
    }

    address lastRecipient = feeRecipients[numberOfRecipients - 1];

    feeGained[lastRecipient] = feeGained[lastRecipient].add(feeAmount).sub(
      feeCharged
    );

    feeStatus.totalFeeAmount = feeStatus.totalFeeAmount.add(feeAmount);
  }

  function _burnLiquidatedTokens(
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    address liquidator,
    uint256 amount
  ) internal {
    positionManagerData.tokenCurrency.safeTransferFrom(
      liquidator,
      address(this),
      amount
    );
    positionManagerData.tokenCurrency.burn(amount);
  }

  function _incrementCollateralBalances(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount
  ) internal {
    positionData.rawCollateral = positionData.rawCollateral.add(
      collateralAmount
    );
    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .add(collateralAmount);
  }

  function _decrementCollateralBalances(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount
  ) internal {
    positionData.rawCollateral = positionData.rawCollateral.sub(
      collateralAmount
    );
    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(collateralAmount);
  }

  //remove the withdrawn collateral from the position and then check its CR
  function _decrementCollateralBalancesCheckCR(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount
  ) internal {
    FixedPoint.Unsigned memory newRawCollateral =
      positionData.rawCollateral.sub(collateralAmount);

    positionData.rawCollateral = newRawCollateral;

    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(collateralAmount);

    require(
      _checkCollateralization(
        positionManagerData,
        newRawCollateral,
        positionData.tokensOutstanding,
        _getOraclePrice(positionManagerData),
        getCollateralDecimals(positionManagerData.collateralToken)
      ),
      'CR is not sufficiently high after the withdraw - try less amount'
    );
  }

  // Deletes a sponsor's position and updates global counters. Does not make any external transfers.
  function _deleteSponsorPosition(
    ICreditLineStorage.PositionData storage positionToLiquidate,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    address sponsor
  ) internal returns (FixedPoint.Unsigned memory) {
    // Remove the collateral and outstanding from the overall total position.
    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(positionToLiquidate.rawCollateral);
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(positionToLiquidate.tokensOutstanding);

    // delete position entry from storage
    CreditLine(address(this)).deleteSponsorPosition(sponsor);

    emit EndedSponsorPosition(sponsor);

    // Return unlocked amount of collateral
    return positionToLiquidate.rawCollateral;
  }

  function _reducePosition(
    ICreditLineStorage.PositionData storage positionToLiquidate,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    FixedPoint.Unsigned memory tokensToLiquidate,
    FixedPoint.Unsigned memory collateralToLiquidate
  ) internal {
    // reduce position
    positionToLiquidate.tokensOutstanding = positionToLiquidate
      .tokensOutstanding
      .sub(tokensToLiquidate);
    positionToLiquidate.rawCollateral = positionToLiquidate.rawCollateral.sub(
      collateralToLiquidate
    );

    // update global position data
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToLiquidate);
    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(collateralToLiquidate);
  }

  function _checkCollateralization(
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory oraclePrice,
    uint8 collateralDecimals
  ) internal view returns (bool) {
    // calculate the min collateral of numTokens with chainlink
    FixedPoint.Unsigned memory thresholdValue =
      numTokens.mul(oraclePrice).div(10**(18 - collateralDecimals));

    thresholdValue = getOverCollateralizationLimit(
      thresholdValue,
      positionManagerData._getCollateralRequirement()
    );

    return collateral.isGreaterThanOrEqual(thresholdValue);
  }

  // Check new total number of tokens does not overcome mint limit
  function checkMintLimit(
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view {
    require(
      globalPositionData.totalTokensOutstanding.isLessThanOrEqual(
        positionManagerData._getCapMintAmount()
      ),
      'Total amount minted overcomes mint limit'
    );
  }

  /**
   * @notice Retrun the on-chain oracle price for a pair
   * @return priceRate Latest rate of the pair
   */
  function _getOraclePrice(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory priceRate) {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        positionManagerData.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.PriceFeed
        )
      );
    priceRate = FixedPoint.Unsigned(
      priceFeed.getLatestPrice(positionManagerData.priceIdentifier)
    );
  }

  /// @notice calls CreditLineController to retrieve liquidation reward percentage
  function _getLiquidationReward(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory liqRewardPercentage) {
    liqRewardPercentage = FixedPoint.Unsigned(
      positionManagerData
        .getCreditLineController()
        .getLiquidationRewardPercentage(address(this))
    );
  }

  function _getFeeInfo(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (ICreditLineStorage.Fee memory fee) {
    fee = positionManagerData.getCreditLineController().getFeeInfo(
      address(this)
    );
  }

  function _getCollateralRequirement(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory) {
    return
      FixedPoint.Unsigned(
        positionManagerData.getCreditLineController().getCollateralRequirement(
          address(this)
        )
      );
  }

  // Get mint amount limit from CreditLineController
  function _getCapMintAmount(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory capMint) {
    capMint = FixedPoint.Unsigned(
      positionManagerData.getCreditLineController().getCapMintAmount(
        address(this)
      )
    );
  }

  // Get self-minting controller instance
  function getCreditLineController(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (ICreditLineController creditLineController) {
    creditLineController = ICreditLineController(
      positionManagerData.synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.CreditLineController
      )
    );
  }

  function getCollateralDecimals(IStandardERC20 collateralToken)
    internal
    view
    returns (uint8 decimals)
  {
    decimals = collateralToken.decimals();
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token
   * @param numTokens Amount of synthetic tokens from which you want to calculate collateral amount
   * @param priceRate On-chain price rate
   * @return collateralAmount Amount of collateral after on-chain oracle conversion
   */
  function calculateCollateralAmount(
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory priceRate,
    uint256 collateraDecimals
  ) internal pure returns (FixedPoint.Unsigned memory collateralAmount) {
    collateralAmount = numTokens.mul(priceRate).div(
      10**(18 - collateraDecimals)
    );
  }

  function getOverCollateralizationLimit(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory collateralRequirementPrc
  ) internal pure returns (FixedPoint.Unsigned memory) {
    return collateral.mul(collateralRequirementPrc);
  }
}