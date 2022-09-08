// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./IdleCDO.sol";
import "./strategies/euler/IdleLeveragedEulerStrategy.sol";

/// @title IdleCDO variant for Euler Levereged strategy. 
/// @author Idle DAO, @bugduino
/// @dev In this variant the `_checkDefault` calculates if strategy price decreased 
/// more than X% with X configurable
contract IdleCDOLeveregedEulerVariant is IdleCDO {
  using SafeERC20Upgradeable for IERC20Detailed;
  // This variable will get appended at the end of the IdleCDOStorage
  // be careful when upgrading
  uint256 public maxDecreaseDefault;
  uint256 public lastAAPrice;
  uint256 public lastBBPrice;

  function _additionalInit() internal override {
    maxDecreaseDefault = 5000; // 5%
    lastAAPrice = oneToken;
    lastBBPrice = oneToken;
  }

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

  /// @notice mint tranche tokens and updates tranche last NAV and lastXXPrice if needed
  /// @param _amount, in underlyings, to convert in tranche tokens
  /// @param _to receiver address of the newly minted tranche tokens
  /// @param _tranche tranche address
  /// @return _minted number of tranche tokens minted
  function _mintShares(uint256 _amount, address _to, address _tranche) internal override returns (uint256 _minted) {
    // calculate # of tranche token to mint based on current tranche price: _amount / tranchePrice
    uint256 _currPrice = _tranchePrice(_tranche);
    uint256 _lastAAPrice = lastAAPrice;
    uint256 _lastBBPrice = lastBBPrice;
    bool _isAA = _tranche == AATranche;
    uint256 _mintPrice = _isAA ? _lastAAPrice : _lastBBPrice;
    // always mint at the highest price
    uint256 _price = _currPrice > _mintPrice ? _currPrice : _mintPrice;

    _minted = _amount * ONE_TRANCHE_TOKEN / _price;
    IdleCDOTranche(_tranche).mint(_to, _minted);

    // update NAV with the _amount of underlyings added
    // and update lastXXPrice if > than before
    if (_isAA) {
      lastNAVAA += _amount;
      if (_price > _lastAAPrice) {
        lastAAPrice = _price;
      }
    } else {
      lastNAVBB += _amount;
      if (_price > _lastBBPrice) {
        lastBBPrice = _price;
      }
    }
  }

  /// @notice calculates the current total value locked (in `token` terms) using mintPrice.
  /// @dev unclaimed rewards (gov tokens) are not counted.
  /// NOTE: `unclaimedFees` are not included in the contract value
  /// NOTE2: fees that *will* be taken (in the next _updateAccounting call) are counted
  /// NOTE3: mintPrice is used instead of _strategyPrice()
  function getContractValueForMint() internal view returns (uint256 _value) {
    address _strategyToken = strategyToken;
    uint256 strategyTokenDecimals = IERC20Detailed(_strategyToken).decimals();
    uint256 mintPrice = IdleLeveragedEulerStrategy(strategy).mintPrice();
    uint256 _price = _strategyPrice();

    _price = mintPrice > _price ? mintPrice : _price;
    // TVL is the sum of unlent balance in the contract + the balance in lending - the reduction for harvested rewards - unclaimedFees
    // the balance in lending is the value of the interest bearing assets (strategyTokens) in this contract
    // TVL = (strategyTokens * strategy token price) + unlent balance - unclaimedFees
    _value= (_contractTokenBalance(_strategyToken) * _price / (10**(strategyTokenDecimals))) +
            _contractTokenBalance(token) -
            unclaimedFees;
  }

  /// @notice calculates the current tranches price considering the interest/loss that is yet to be splitted
  /// ie the interest/loss generated since the last update of priceAA and priceBB (done on depositXX/withdrawXX/harvest)
  /// this is called at the end of each harvests and considers
  /// @param _tranche address of the requested tranche
  /// @return _virtualPrice tranche price considering all interest/losses
  function virtualPriceMint(address _tranche) public view returns (uint256 _virtualPrice) {
    // get both NAVs, because we need the total NAV anyway
    uint256 _lastNAVAA = lastNAVAA;
    uint256 _lastNAVBB = lastNAVBB;

    (_virtualPrice, ) = _virtualPriceAuxVariant(
      _tranche,
      getContractValueForMint(), // nav
      _lastNAVAA + _lastNAVBB, // lastNAV
      _tranche == AATranche ? _lastNAVAA : _lastNAVBB, // lastTrancheNAV
      trancheAPRSplitRatio,
      true
    );
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
      trancheAPRSplitRatio,
      false
    );
  }

  /// @notice calculates the current tranches price considering the interest/loss that is yet to be splitted and the
  /// total gain/loss for a specific tranche
  /// @param _tranche address of the requested tranche
  /// @param _nav current NAV
  /// @param _lastNAV last saved NAV
  /// @param _lastTrancheNAV last saved tranche NAV
  /// @param _trancheAPRSplitRatio APR split ratio for AA tranche
  /// @param isForMint flag if is for mint to avoid calculating fees
  /// @return _virtualPrice tranche price considering all interest
  /// @return _totalTrancheGain (int256) tranche gain/loss since last update
  function _virtualPriceAuxVariant(
    address _tranche,
    uint256 _nav,
    uint256 _lastNAV,
    uint256 _lastTrancheNAV,
    uint256 _trancheAPRSplitRatio,
    bool isForMint
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
    if (totalGain > 0 && !isForMint) {
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
    (uint256 _priceAA, int256 _totalAAGain) = _virtualPriceAuxVariant(AATranche, nav, _lastNAV, _lastNAVAA, _aprSplitRatio, false);
    (uint256 _priceBB, int256 _totalBBGain) = _virtualPriceAuxVariant(BBTranche, nav, _lastNAV, _lastNAVBB, _aprSplitRatio, false);

    lastNAVAA = uint256(int256(_lastNAVAA) + _totalAAGain);
    lastNAVBB = uint256(int256(_lastNAVBB) + _totalBBGain);
    priceAA = _priceAA;
    priceBB = _priceBB;
  }

  function harvest(
    // _skipFlags[0] _skipRedeem,
    // _skipFlags[1] _skipIncentivesUpdate,
    // _skipFlags[2] _skipFeeDeposit,
    // _skipFlags[3] _skipRedeem && _skipIncentivesUpdate && _skipFeeDeposit,
    bool[] calldata _skipFlags,
    bool[] calldata _skipReward,
    uint256[] calldata _minAmount,
    uint256[] calldata _sellAmounts,
    bytes calldata _extraData
  ) public
    override
    returns (uint256[][] memory _res) {
      _res = super.harvest(_skipFlags, _skipReward, _minAmount, _sellAmounts, _extraData);
      // if some rewards have been sold update lastXXPrice if needed
      if (_res[2].length > 0) {
        uint256 _virtualMintAA = virtualPriceMint(AATranche);
        uint256 _virtualMintBB = virtualPriceMint(BBTranche);
        if (_virtualMintAA > lastAAPrice) {
          lastAAPrice = _virtualMintAA;
        }
        if (_virtualMintBB > lastBBPrice) {
          lastBBPrice = _virtualMintBB;
        }
      }
  }
}