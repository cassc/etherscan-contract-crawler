/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

pragma experimental ABIEncoderV2;





interface ICrvUsdController {
    function create_loan(uint256 _collateralAmount, uint256 _debtAmount, uint256 _nBands) external payable;
    function create_loan_extended(uint256 _collateralAmount, uint256 _debtAmount, uint256 _nBands, address _callbacker, uint256[] memory _callbackArgs) external payable;

    /// @dev all functions below: if _collateralAmount is 0 will just return
    function add_collateral(uint256 _collateralAmount) external payable;
    function add_collateral(uint256 _collateralAmount, address _for) external payable;

    function remove_collateral(uint256 _collateralAmount) external;
    /// @param _useEth relevant only for ETH collateral pools (currently not deployed)
    function remove_collateral(uint256 _collateralAmount, bool _useEth) external;

    /// @dev all functions below: if _debtAmount is 0 will just return
    function borrow_more(uint256 _collateralAmount, uint256 _debtAmount) external payable;

    /// @dev if _debtAmount > debt will do full repay
    function repay(uint256 _debtAmount) external payable;
    function repay(uint256 _debtAmount, address _for) external payable;
    /// @param _maxActiveBand Don't allow active band to be higher than this (to prevent front-running the repay)
    function repay(uint256 _debtAmount, address _for, int256 _maxActiveBand) external payable;
    function repay(uint256 _debtAmount, address _for, int256 _maxActiveBand, bool _useEth) external payable;
    function repay_extended(address _callbacker, uint256[] memory _callbackArgs) external;

    function liquidate(address user, uint256 min_x) external;
    function liquidate(address user, uint256 min_x, bool _useEth) external;
    function liquidate_extended(address user, uint256 min_x, uint256 frac, bool use_eth, address callbacker, uint256[] memory _callbackArgs) external;


    /// GETTERS
    function amm() external view returns (address);
    function monetary_policy() external view returns (address);
    function collateral_token() external view returns (address);
    function debt(address) external view returns (uint256);
    function total_debt() external view returns (uint256);
    function health_calculator(address, int256, int256, bool, uint256) external view returns (int256);
    function health_calculator(address, int256, int256, bool) external view returns (int256);
    function health(address) external view returns (int256);
    function health(address, bool) external view returns (int256);
    function max_borrowable(uint256 collateralAmount, uint256 nBands) external view returns (uint256);
    function min_collateral(uint256 debtAmount, uint256 nBands) external view returns (uint256);
    function calculate_debt_n1(uint256, uint256, uint256) external view returns (int256);
    function minted() external view returns (uint256);
    function redeemed() external view returns (uint256);
    function amm_price() external view returns (uint256);
    function user_state(address) external view returns (uint256[4] memory);
    function user_prices(address) external view returns (uint256[2] memory);
    function loan_exists(address) external view returns (bool);
    function liquidation_discount() external view returns (uint256);
}

interface ICrvUsdControllerFactory {
    function get_controller(address) external view returns (address); 
    function debt_ceiling(address) external view returns (uint256);
}

interface ILLAMMA {
    function active_band_with_skip() external view returns (int256);
    function get_sum_xy(address) external view returns (uint256[2] memory);
    function get_xy(address) external view returns (uint256[][2] memory);
    function get_p() external view returns (uint256);
    function read_user_tick_numbers(address) external view returns (int256[2] memory);
    function p_oracle_up(int256) external view returns (uint256);
    function p_oracle_down(int256) external view returns (uint256);
    function p_current_up(int256) external view returns (uint256);
    function p_current_down(int256) external view returns (uint256);
    function bands_x(int256) external view returns (uint256);
    function bands_y(int256) external view returns (uint256);
    function get_base_price() external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function active_band() external view returns (int256);
    function A() external view returns (uint256);
    function min_band() external view returns (int256);
    function max_band() external view returns (int256);
    function rate() external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 in_amount, uint256 min_amount) external returns (uint256[2] memory);
    function coins(uint256 i) external view returns (address);
    function user_state(address _user) external view returns (uint256[4] memory);
}

interface IAGG {
    function rate() external view returns (uint256);
    function rate0() external view returns (uint256);
    function target_debt_fraction() external view returns (uint256);
    function sigma() external view returns (int256);
    function peg_keepers(uint256) external view returns (address); 
}

interface IPegKeeper {
    function debt() external view returns (uint256);
}

interface ICurveUsdSwapper {
    function encodeSwapParams(uint256[3][4] memory swapParams,  uint32 gasUsed, uint32 dfsFeeDivider, uint8 useSteth) external pure returns (uint256 encoded);
    function setAdditionalRoutes(address[6] memory _additionalRoutes) external;
}





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}






contract CurveUsdView {
  struct Band {
    int256 id;
    uint256 lowPrice;
    uint256 highPrice;
    uint256 collAmount;
    uint256 debtAmount;
  }

  struct CreateLoanData {
    int256 health;
    uint256 minColl;
    uint256 maxBorrow;
    Band[] bands;
  }

  struct GlobalData {
    address collateral;
    uint256 decimals;
    int256 activeBand;
    uint256 A;
    uint256 totalDebt;
    uint256 ammPrice;
    uint256 basePrice;
    uint256 oraclePrice;
    uint256 minted;
    uint256 redeemed;
    uint256 monetaryPolicyRate;
    uint256 ammRate;
    int256 minBand;
    int256 maxBand;
  }

  struct UserData {
    bool loanExists;
    uint256 collateralPrice;
    uint256 marketCollateralAmount;
    uint256 curveUsdCollateralAmount;
    uint256 debtAmount;
    uint256 N;
    uint256 priceLow;
    uint256 priceHigh;
    uint256 liquidationDiscount;
    int256 health;
    int256[2] bandRange;
    uint256[][2] usersBands;
  }

  function userData(address market, address user) external view returns (UserData memory) {
      ICrvUsdController ctrl = ICrvUsdController(market);
      ILLAMMA amm = ILLAMMA(ctrl.amm());

      if (!ctrl.loan_exists(user)) {
        int256[2] memory bandRange = [int256(0), int256(0)];
        uint256[][2] memory usersBands;

        return UserData({
          loanExists: false,
          collateralPrice: 0,
          marketCollateralAmount: 0,
          curveUsdCollateralAmount: 0,
          debtAmount: 0,
          N: 0,
          priceLow: 0,
          priceHigh: 0,
          liquidationDiscount: 0,
          health: 0,
          bandRange: bandRange,
          usersBands: usersBands
        });
      }

      uint256[4] memory amounts = ctrl.user_state(user);
      uint256[2] memory prices = ctrl.user_prices(user);

      return UserData({
        loanExists: ctrl.loan_exists(user),
        collateralPrice: ctrl.amm_price(),
        marketCollateralAmount: amounts[0],
        curveUsdCollateralAmount: amounts[1],
        debtAmount: amounts[2],
        N: amounts[3],
        priceLow: prices[1],
        priceHigh: prices[0],
        liquidationDiscount: ctrl.liquidation_discount(),
        health: ctrl.health(user, true),
        bandRange: amm.read_user_tick_numbers(user),
        usersBands: amm.get_xy(user)
      });
  }

  function globalData(address market) external view returns (GlobalData memory) {
      ICrvUsdController ctrl = ICrvUsdController(market);
      IAGG agg = IAGG(ctrl.monetary_policy());
      ILLAMMA amm = ILLAMMA(ctrl.amm());
      address collTokenAddr = ctrl.collateral_token();

      return GlobalData({
        collateral: collTokenAddr,
        decimals: IERC20(collTokenAddr).decimals(),
        activeBand: amm.active_band(),
        A: amm.A(),
        totalDebt: ctrl.total_debt(),
        ammPrice: ctrl.amm_price(),
        basePrice: amm.get_base_price(),
        oraclePrice: amm.price_oracle(),
        minted: ctrl.minted(),
        redeemed: ctrl.redeemed(),
        monetaryPolicyRate: agg.rate(),
        ammRate: amm.rate(),
        minBand: amm.min_band(),
        maxBand: amm.max_band()
    });
  }

  function getBandData(address market, int256 n) external view returns (Band memory) {
      ICrvUsdController ctrl = ICrvUsdController(market);
      ILLAMMA lama = ILLAMMA(ctrl.amm());

      return Band(n, lama.p_oracle_down(n), lama.p_oracle_up(n), lama.bands_y(n), lama.bands_x(n));
  }
  
  function getBandsData(address market, int256 from, int256 to) public view returns (Band[] memory) {
      ICrvUsdController ctrl = ICrvUsdController(market);
      ILLAMMA lama = ILLAMMA(ctrl.amm());
      Band[] memory bands = new Band[](uint256(to-from+1));
      for (int256 i = from; i <= to; i++) {
          bands[uint256(i-from)] = Band(i, lama.p_oracle_down(i), lama.p_oracle_up(i), lama.bands_y(i), lama.bands_x(i));
      }

      return bands;
  }

  function createLoanData(address market, uint256 collateral, uint256 debt, uint256 N) external view returns (CreateLoanData memory) {
    ICrvUsdController ctrl = ICrvUsdController(market);

    address collAsset = ctrl.collateral_token();

    // health_calculator needs to receive assets in 18 decimals
    uint256 assetDec = IERC20(collAsset).decimals();
    uint256 collForHealthCalc = collateral;

    collForHealthCalc = assetDec > 18 ? (collateral / 10 ** (assetDec - 18)) : (collateral * 10 ** (18 - assetDec));

    int256 health = ctrl.health_calculator(address(0x00), int256(collForHealthCalc), int256(debt), true, N);

    int256 n1 = ctrl.calculate_debt_n1(collateral, debt, N);
    int256 n2 = n1 + int256(N) - 1;

    Band[] memory bands = getBandsData(market, n1, n2);

    return CreateLoanData({
      health: health,
      minColl: ctrl.min_collateral(debt, N),
      maxBorrow: ctrl.max_borrowable(collateral, N),
      bands: bands
    });
  }

  function maxBorrow(address market, uint256 collateral, uint256 N) external view returns (uint256) {
    ICrvUsdController ctrl = ICrvUsdController(market);
    return ctrl.max_borrowable(collateral, N);
  }

  function minCollateral(address market, uint256 debt, uint256 N) external view returns (uint256) {
    ICrvUsdController ctrl = ICrvUsdController(market);
    return ctrl.min_collateral(debt, N);
  }

  function getBandsData(address market, uint256 collateral, uint256 debt, uint256 N) external view returns (Band[] memory bands) {
    ICrvUsdController ctrl = ICrvUsdController(market);

    int256 n1 = ctrl.calculate_debt_n1(collateral, debt, N);
    int256 n2 = n1 + int256(N) - 1;

    bands = getBandsData(market, n1, n2);
  }

  function healthCalculator(address market, address user, int256 collChange, int256 debtChange, bool isFull, uint256 numBands) external view returns (int256) {
    ICrvUsdController ctrl = ICrvUsdController(market);
    return ctrl.health_calculator(user, collChange, debtChange, isFull, numBands);
  }
}