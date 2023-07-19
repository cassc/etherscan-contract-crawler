// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Governed.sol";
import "./IProvider.sol";
import "./ISmartYield.sol";

abstract contract IController is Governed {

    uint256 public constant EXP_SCALE = 1e18;

    address public pool; // compound provider pool

    address public smartYield; // smartYield

    address public oracle; // IYieldOracle

    address public bondModel; // IBondModel

    address public feesOwner; // fees are sent here

    // max accepted cost of harvest when converting COMP -> underlying,
    // if harvest gets less than (COMP to underlying at spot price) - HARVEST_COST%, it will revert.
    // if it gets more, the difference goes to the harvest caller
    uint256 public HARVEST_COST = 40 * 1e15; // 4%

    // fee for buying jTokens
    uint256 public FEE_BUY_JUNIOR_TOKEN = 3 * 1e15; // 0.3%

    // fee for redeeming a sBond
    uint256 public FEE_REDEEM_SENIOR_BOND = 100 * 1e15; // 10%

    // max rate per day for sBonds
    uint256 public BOND_MAX_RATE_PER_DAY = 719065000000000; // APY 30% / year

    // max duration of a purchased sBond
    uint16 public BOND_LIFE_MAX = 90; // in days

    bool public PAUSED_BUY_JUNIOR_TOKEN = false;

    bool public PAUSED_BUY_SENIOR_BOND = false;

    function setHarvestCost(uint256 newValue_)
      public
      onlyDao
    {
        require(
          HARVEST_COST < EXP_SCALE,
          "IController: HARVEST_COST too large"
        );
        HARVEST_COST = newValue_;
    }

    function setBondMaxRatePerDay(uint256 newVal_)
      public
      onlyDao
    {
      BOND_MAX_RATE_PER_DAY = newVal_;
    }

    function setBondLifeMax(uint16 newVal_)
      public
      onlyDao
    {
      BOND_LIFE_MAX = newVal_;
    }

    function setFeeBuyJuniorToken(uint256 newVal_)
      public
      onlyDao
    {
      FEE_BUY_JUNIOR_TOKEN = newVal_;
    }

    function setFeeRedeemSeniorBond(uint256 newVal_)
      public
      onlyDao
    {
      FEE_REDEEM_SENIOR_BOND = newVal_;
    }

    function setPaused(bool buyJToken_, bool buySBond_)
      public
      onlyDaoOrGuardian
    {
      PAUSED_BUY_JUNIOR_TOKEN = buyJToken_;
      PAUSED_BUY_SENIOR_BOND = buySBond_;
    }

    function setOracle(address newVal_)
      public
      onlyDao
    {
      oracle = newVal_;
    }

    function setBondModel(address newVal_)
      public
      onlyDao
    {
      bondModel = newVal_;
    }

    function setFeesOwner(address newVal_)
      public
      onlyDao
    {
      feesOwner = newVal_;
    }

    function yieldControllTo(address newController_)
      public
      onlyDao
    {
      IProvider(pool).setController(newController_);
      ISmartYield(smartYield).setController(newController_);
    }

    function providerRatePerDay() external virtual returns (uint256);
}