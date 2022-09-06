// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./IdleCDO.sol";

/// @title IdleCDO variant for Euler Levereged strategy. 
/// @author Idle DAO, @bugduino
/// @dev In this variant the `_checkDefault` calculates if strategy price decreased 
/// more than X% with X configurable
contract IdleCDOLeveregedEulerVariant is IdleCDO {
  using SafeERC20Upgradeable for IERC20Detailed;
  // This variable will get appended at the end of the IdleCDOStorage
  // be careful when upgrading
  uint256 public maxDecreaseDefault;

  /// @dev check if any loan for the pool is defaulted
  function _checkDefault() override internal view {
    uint256 _lastPrice = lastStrategyPrice;

    // calculate max % decrease
    if (!skipDefaultCheck) {
      require(_lastPrice - (_lastPrice * maxDecreaseDefault / FULL_ALLOC) <= _strategyPrice(), "4");
    }
  }

  /// @notice set the max value, in % where `100000` = 100%, of accettable price decrease for the strategy
  /// @dev automatically reverts if strategyPrice decreased more than `_maxDecreaseDefault`
  /// @param _maxDecreaseDefault in tranche tokens
  function setMaxDecreaseDefault(uint256 _maxDecreaseDefault) external {
    _checkOnlyOwner();
    require(_maxDecreaseDefault < FULL_ALLOC);
    maxDecreaseDefault = _maxDecreaseDefault;
  }

  /// @notice calculates the current tranches price considering the interest/loss that is yet to be splitted
  /// ie the interest/loss generated since the last update of priceAA and priceBB (done on depositXX/withdrawXX/harvest)
  /// useful for showing updated gains on frontends
  /// @param _tranche address of the requested tranche
  /// @return _virtualPrice tranche price considering all interest/losses
  function virtualPrice(address _tranche) public override view returns (uint256 _virtualPrice) {
    // get both NAVs, because we need the total NAV anyway
    uint256 _lastNAVAA = lastNAVAA;
    uint256 _lastNAVBB = lastNAVBB;

    (_virtualPrice, ) = _virtualPriceAuxVariant(
      _tranche,
      getContractValue(), // nav
      _lastNAVAA + _lastNAVBB, // lastNAV
      _tranche == AATranche ? _lastNAVAA : _lastNAVBB, // lastTrancheNAV
      trancheAPRSplitRatio
    );
  }

  /// @notice calculates the current tranches price considering the interest/loss that is yet to be splitted and the
  /// total gain/loss for a specific tranche
  /// @param _tranche address of the requested tranche
  /// @param _nav current NAV
  /// @param _lastNAV last saved NAV
  /// @param _lastTrancheNAV last saved tranche NAV
  /// @param _trancheAPRSplitRatio APR split ratio for AA tranche
  /// @return _virtualPrice tranche price considering all interest
  /// @return _totalTrancheGain (int256) tranche gain/loss since last update
  function _virtualPriceAuxVariant(
    address _tranche,
    uint256 _nav,
    uint256 _lastNAV,
    uint256 _lastTrancheNAV,
    uint256 _trancheAPRSplitRatio
  ) internal view returns (uint256 _virtualPrice, int256 _totalTrancheGain) {
    // Check if there are tranche holders
    uint256 trancheSupply = IdleCDOTranche(_tranche).totalSupply();
    if (_lastNAV == 0 || trancheSupply == 0) {
      return (oneToken, 0);
    }
    // In order to correctly split the interest or loss generated between AA and BB tranche holders
    // (according to the trancheAPRSplitRatio) we need to know how much interest/loss we gained
    // since the last price update (during a depositXX/withdrawXX/harvest)
    // To do that we need to get the current value of the assets in this contract
    // and the last saved one (always during a depositXX/withdrawXX/harvest)
    // Calculate the total gain
    int256 totalGain = int256(_nav) - int256(_lastNAV);

    // Remove performance fee
    if (totalGain > 0) {
      totalGain -= totalGain * int256(fee) / int256(FULL_ALLOC);
    }

    address _AATranche = AATranche;
    bool _isAATranche = _tranche == _AATranche;
    // Get the supply of the other tranche and
    // if it's 0 then give all gain to the current `_tranche` holders
    if (IdleCDOTranche(_isAATranche ? BBTranche : _AATranche).totalSupply() == 0) {
      _totalTrancheGain = totalGain;
    } else {
      // Split the net gain, with precision loss favoring the AA tranche.
      int256 totalBBGain = totalGain * int256(FULL_ALLOC - _trancheAPRSplitRatio) / int256(FULL_ALLOC);
      // The new NAV for the tranche is old NAV + total gain for the tranche
      _totalTrancheGain = _isAATranche ? (totalGain - totalBBGain) : totalBBGain;
    }
    // Split the new NAV (_lastTrancheNAV + _totalTrancheGain) per tranche token
    _virtualPrice = uint256(int256(_lastTrancheNAV) + int256(_totalTrancheGain)) * ONE_TRANCHE_TOKEN / trancheSupply;
  }

  /// @notice this method is called on depositXX/withdrawXX/harvest and
  /// updates the accounting of the contract and effectively splits the yield/loss between the
  /// AA and BB tranches
  /// @dev this method:
  /// - update tranche prices (priceAA and priceBB)
  /// - update net asset value for both tranches (lastNAVAA and lastNAVBB)
  /// - update fee accounting (unclaimedFees)
  function _updateAccounting() internal override {
    uint256 _lastNAVAA = lastNAVAA;
    uint256 _lastNAVBB = lastNAVBB;
    uint256 _lastNAV = _lastNAVAA + _lastNAVBB;
    uint256 nav = getContractValue();
    uint256 _aprSplitRatio = trancheAPRSplitRatio;

    // If gain is > 0, then collect some fees in `unclaimedFees`
    if (nav > _lastNAV) {
      unclaimedFees += (nav - _lastNAV) * fee / FULL_ALLOC;
    }

    (uint256 _priceAA, int256 _totalAAGain) = _virtualPriceAuxVariant(AATranche, nav, _lastNAV, _lastNAVAA, _aprSplitRatio);
    (uint256 _priceBB, int256 _totalBBGain) = _virtualPriceAuxVariant(BBTranche, nav, _lastNAV, _lastNAVBB, _aprSplitRatio);

    lastNAVAA = uint256(int256(_lastNAVAA) + _totalAAGain);
    lastNAVBB = uint256(int256(_lastNAVBB) + _totalBBGain);
    priceAA = _priceAA;
    priceBB = _priceBB;
  }
}