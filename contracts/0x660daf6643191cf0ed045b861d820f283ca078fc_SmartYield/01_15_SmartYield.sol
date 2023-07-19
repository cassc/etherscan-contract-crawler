// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./lib/math/MathUtils.sol";

import "./IController.sol";
import "./ISmartYield.sol";

import "./IProvider.sol";

import "./model/IBondModel.sol";
import "./IBond.sol";
import "./JuniorToken.sol";

contract SmartYield is
    JuniorToken,
    ISmartYield
{
    using SafeMath for uint256;

    uint256 public constant MAX_UINT256 = uint256(-1);
    uint256 public constant EXP_SCALE = 1e18;

    // controller address
    address public override controller;

    // address of IProviderPool
    address public pool;

    // senior BOND (NFT)
    address public seniorBond; // IBond

    // junior BOND (NFT)
    address public juniorBond; // IBond

    // underlying amount in matured and liquidated juniorBonds
    uint256 public underlyingLiquidatedJuniors;

    // tokens amount in unmatured juniorBonds or matured and unliquidated
    uint256 public tokensInJuniorBonds;

    // latest SeniorBond Id
    uint256 public seniorBondId;

    // latest JuniorBond Id
    uint256 public juniorBondId;

    // last index of juniorBondsMaturities that was liquidated
    uint256 public juniorBondsMaturitiesPrev;
    // list of junior bond maturities (timestamps)
    uint256[] public juniorBondsMaturities;

    // checkpoints for all JuniorBonds matureing at (timestamp) -> (JuniorBondsAt)
    // timestamp -> JuniorBondsAt
    mapping(uint256 => JuniorBondsAt) public juniorBondsMaturingAt;

    // metadata for senior bonds
    // bond id => bond (SeniorBond)
    mapping(uint256 => SeniorBond) public seniorBonds;

    // metadata for junior bonds
    // bond id => bond (JuniorBond)
    mapping(uint256 => JuniorBond) public juniorBonds;

    // pool state / average bond
    // holds rate of payment by juniors to seniors
    SeniorBond public abond;

    bool public _setup;

    // emitted when user buys junior ERC20 tokens
    event BuyTokens(address indexed buyer, uint256 underlyingIn, uint256 tokensOut, uint256 fee);
    // emitted when user sells junior ERC20 tokens and forfeits their share of the debt
    event SellTokens(address indexed seller, uint256 tokensIn, uint256 underlyingOut, uint256 forfeits);

    event BuySeniorBond(address indexed buyer, uint256 indexed seniorBondId, uint256 underlyingIn, uint256 gain, uint256 forDays);

    event RedeemSeniorBond(address indexed owner, uint256 indexed seniorBondId, uint256 fee);

    event BuyJuniorBond(address indexed buyer, uint256 indexed juniorBondId, uint256 tokensIn, uint256 maturesAt);

    event RedeemJuniorBond(address indexed owner, uint256 indexed juniorBondId, uint256 underlyingOut);

    modifier onlyControllerOrDao {
      require(
        msg.sender == controller || msg.sender == IController(controller).dao(),
        "PPC: only controller/DAO"
      );
      _;
    }

    constructor(
      string memory name_,
      string memory symbol_,
      uint8 decimals_
    )
      JuniorToken(name_, symbol_, decimals_)
    {}

    function setup(
      address controller_,
      address pool_,
      address seniorBond_,
      address juniorBond_
    )
      external
    {
        require(
          false == _setup,
          "SY: already setup"
        );

        controller = controller_;
        pool = pool_;
        seniorBond = seniorBond_;
        juniorBond = juniorBond_;

        _setup = true;
    }

    // externals

    // change the controller, only callable by old controller or dao
    function setController(address newController_)
      external override
      onlyControllerOrDao
    {
      controller = newController_;
    }

    // buy at least _minTokens with _underlyingAmount, before _deadline passes
    function buyTokens(
      uint256 underlyingAmount_,
      uint256 minTokens_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
          false == IController(controller).PAUSED_BUY_JUNIOR_TOKEN(),
          "SY: buyTokens paused"
        );

        require(
          block.timestamp <= deadline_,
          "SY: buyTokens deadline"
        );

        uint256 fee = MathUtils.fractionOf(underlyingAmount_, IController(controller).FEE_BUY_JUNIOR_TOKEN());
        // (underlyingAmount_ - fee) * EXP_SCALE / price()
        uint256 getsTokens = (underlyingAmount_.sub(fee)).mul(EXP_SCALE).div(price());

        require(
          getsTokens >= minTokens_,
          "SY: buyTokens minTokens"
        );

        // ---

        address buyer = msg.sender;

        IProvider(pool)._takeUnderlying(buyer, underlyingAmount_);
        IProvider(pool)._depositProvider(underlyingAmount_, fee);
        _mint(buyer, getsTokens);

        emit BuyTokens(buyer, underlyingAmount_, getsTokens, fee);
    }

    // sell _tokens for at least _minUnderlying, before _deadline and forfeit potential future gains
    function sellTokens(
      uint256 tokenAmount_,
      uint256 minUnderlying_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
          block.timestamp <= deadline_,
          "SY: sellTokens deadline"
        );

        // share of these tokens in the debt
        // tokenAmount_ * EXP_SCALE / totalSupply()
        uint256 debtShare = tokenAmount_.mul(EXP_SCALE).div(totalSupply());
        // (abondDebt() * debtShare) / EXP_SCALE
        uint256 forfeits = abondDebt().mul(debtShare).div(EXP_SCALE);
        // debt share is forfeit, and only diff is returned to user
        // (tokenAmount_ * price()) / EXP_SCALE - forfeits
        uint256 toPay = tokenAmount_.mul(price()).div(EXP_SCALE).sub(forfeits);

        require(
          toPay >= minUnderlying_,
          "SY: sellTokens minUnderlying"
        );

        // ---

        address seller = msg.sender;

        _burn(seller, tokenAmount_);
        IProvider(pool)._withdrawProvider(toPay, 0);
        IProvider(pool)._sendUnderlying(seller, toPay);

        emit SellTokens(seller, tokenAmount_, toPay, forfeits);
    }

    // Purchase a senior bond with principalAmount_ underlying for forDays_, buyer gets a bond with gain >= minGain_ or revert. deadline_ is timestamp before which tx is not rejected.
    // returns gain
    function buyBond(
        uint256 principalAmount_,
        uint256 minGain_,
        uint256 deadline_,
        uint16 forDays_
    )
      external override
      returns (uint256)
    {
        _beforeProviderOp(block.timestamp);

        require(
          false == IController(controller).PAUSED_BUY_SENIOR_BOND(),
          "SY: buyBond paused"
        );

        require(
          block.timestamp <= deadline_,
          "SY: buyBond deadline"
        );

        require(
            0 < forDays_ && forDays_ <= IController(controller).BOND_LIFE_MAX(),
            "SY: buyBond forDays"
        );

        uint256 gain = bondGain(principalAmount_, forDays_);

        require(
          gain >= minGain_,
          "SY: buyBond minGain"
        );

        require(
          gain > 0,
          "SY: buyBond gain 0"
        );

        require(
          gain < underlyingLoanable(),
          "SY: buyBond underlyingLoanable"
        );

        uint256 issuedAt = block.timestamp;

        // ---

        address buyer = msg.sender;

        IProvider(pool)._takeUnderlying(buyer, principalAmount_);
        IProvider(pool)._depositProvider(principalAmount_, 0);

        SeniorBond memory b =
            SeniorBond(
                principalAmount_,
                gain,
                issuedAt,
                uint256(1 days) * uint256(forDays_) + issuedAt,
                false
            );

        _mintBond(buyer, b);

        emit BuySeniorBond(buyer, seniorBondId, principalAmount_, gain, forDays_);

        return gain;
    }

    // buy an nft with tokenAmount_ jTokens, that matures at abond maturesAt
    function buyJuniorBond(
      uint256 tokenAmount_,
      uint256 maxMaturesAt_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        // 1 + abond.maturesAt / EXP_SCALE
        uint256 maturesAt = abond.maturesAt.div(EXP_SCALE).add(1);

        require(
          block.timestamp <= deadline_,
          "SY: buyJuniorBond deadline"
        );

        require(
          maturesAt <= maxMaturesAt_,
          "SY: buyJuniorBond maxMaturesAt"
        );

        JuniorBond memory jb = JuniorBond(
          tokenAmount_,
          maturesAt
        );

        // ---

        address buyer = msg.sender;

        _takeTokens(buyer, tokenAmount_);
        _mintJuniorBond(buyer, jb);

        emit BuyJuniorBond(buyer, juniorBondId, tokenAmount_, maturesAt);

        // if abond.maturesAt is past we can liquidate, but juniorBondsMaturingAt might have already been liquidated
        if (block.timestamp >= maturesAt) {
            JuniorBondsAt memory jBondsAt = juniorBondsMaturingAt[jb.maturesAt];

            if (jBondsAt.price == 0) {
                _liquidateJuniorsAt(jb.maturesAt);
            } else {
                // juniorBondsMaturingAt was previously liquidated,
                _burn(address(this), jb.tokens); // burns user's locked tokens reducing the jToken supply
                // underlyingLiquidatedJuniors += jb.tokens * jBondsAt.price / EXP_SCALE
                underlyingLiquidatedJuniors = underlyingLiquidatedJuniors.add(
                  jb.tokens.mul(jBondsAt.price).div(EXP_SCALE)
                );
                _unaccountJuniorBond(jb);
            }
            return this.redeemJuniorBond(juniorBondId);
        }
    }

    // Redeem a senior bond by it's id. Anyone can redeem but owner gets principal + gain
    function redeemBond(
      uint256 bondId_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
            block.timestamp >= seniorBonds[bondId_].maturesAt,
            "SY: redeemBond not matured"
        );

        // bondToken.ownerOf will revert for burned tokens
        address payTo = IBond(seniorBond).ownerOf(bondId_);
        // seniorBonds[bondId_].gain + seniorBonds[bondId_].principal
        uint256 payAmnt = seniorBonds[bondId_].gain.add(seniorBonds[bondId_].principal);
        uint256 fee = MathUtils.fractionOf(seniorBonds[bondId_].gain, IController(controller).FEE_REDEEM_SENIOR_BOND());
        payAmnt = payAmnt.sub(fee);

        // ---

        if (seniorBonds[bondId_].liquidated == false) {
            seniorBonds[bondId_].liquidated = true;
            _unaccountBond(seniorBonds[bondId_]);
        }

        // bondToken.burn will revert for already burned tokens
        IBond(seniorBond).burn(bondId_);

        IProvider(pool)._withdrawProvider(payAmnt, fee);
        IProvider(pool)._sendUnderlying(payTo, payAmnt);

        emit RedeemSeniorBond(payTo, bondId_, fee);
    }

    // once matured, redeem a jBond for underlying
    function redeemJuniorBond(uint256 jBondId_)
        external override
    {
        _beforeProviderOp(block.timestamp);

        JuniorBond memory jb = juniorBonds[jBondId_];
        require(
            jb.maturesAt <= block.timestamp,
            "SY: redeemJuniorBond maturesAt"
        );

        JuniorBondsAt memory jBondsAt = juniorBondsMaturingAt[jb.maturesAt];

        // blows up if already burned
        address payTo = IBond(juniorBond).ownerOf(jBondId_);
        // jBondsAt.price * jb.tokens / EXP_SCALE
        uint256 payAmnt = jBondsAt.price.mul(jb.tokens).div(EXP_SCALE);

        // ---

        _burnJuniorBond(jBondId_);
        IProvider(pool)._withdrawProvider(payAmnt, 0);
        IProvider(pool)._sendUnderlying(payTo, payAmnt);
        underlyingLiquidatedJuniors = underlyingLiquidatedJuniors.sub(payAmnt);

        emit RedeemJuniorBond(payTo, jBondId_, payAmnt);
    }

    // returns the maximum theoretically possible daily rate for senior bonds,
    // in reality the actual rate given to a bond will always be lower due to slippage
    function maxBondDailyRate()
      external override
    returns (uint256)
    {
      return IBondModel(IController(controller).bondModel()).maxDailyRate(
        underlyingTotal(),
        underlyingLoanable(),
        IController(controller).providerRatePerDay()
      );
    }

    function liquidateJuniorBonds(uint256 upUntilTimestamp_)
      external override
    {
      require(
        upUntilTimestamp_ <= block.timestamp,
        "SY: liquidateJuniorBonds in future"
      );
      _beforeProviderOp(upUntilTimestamp_);
    }

  // /externals

  // publics

    // given a principal amount and a number of days, compute the guaranteed bond gain, excluding principal
    function bondGain(uint256 principalAmount_, uint16 forDays_)
      public override
    returns (uint256)
    {
      return IBondModel(IController(controller).bondModel()).gain(
        underlyingTotal(),
        underlyingLoanable(),
        IController(controller).providerRatePerDay(),
        principalAmount_,
        forDays_
      );
    }

    // jToken price * EXP_SCALE
    function price()
      public override
    returns (uint256)
    {
        uint256 ts = totalSupply();
        // (ts == 0) ? EXP_SCALE : (underlyingJuniors() * EXP_SCALE) / ts
        return (ts == 0) ? EXP_SCALE : underlyingJuniors().mul(EXP_SCALE).div(ts);
    }

    function underlyingTotal()
      public virtual override
    returns(uint256)
    {
      // underlyingBalance() - underlyingLiquidatedJuniors
      return IProvider(pool).underlyingBalance().sub(underlyingLiquidatedJuniors);
    }

    function underlyingJuniors()
      public virtual override
    returns (uint256)
    {
      // underlyingTotal() - abond.principal - abondPaid()
      return underlyingTotal().sub(abond.principal).sub(abondPaid());
    }

    function underlyingLoanable()
      public virtual override
    returns (uint256)
    {
        // underlyingTotal - abond.principal - abond.gain - queued withdrawls
        uint256 _underlyingTotal = underlyingTotal();
        // abond.principal - abond.gain - (tokensInJuniorBonds * price() / EXP_SCALE)
        uint256 _lockedUnderlying = abond.principal.add(abond.gain).add(
          tokensInJuniorBonds.mul(price()).div(EXP_SCALE)
        );

        if (_lockedUnderlying > _underlyingTotal) {
          // abond.gain and (tokensInJuniorBonds in underlying) can overlap, so there is a cases where _lockedUnderlying > _underlyingTotal
          return 0;
        }

        // underlyingTotal() - abond.principal - abond.gain - (tokensInJuniorBonds * price() / EXP_SCALE)
        return _underlyingTotal.sub(_lockedUnderlying);
    }

    function abondGain()
      public view override
    returns (uint256)
    {
        return abond.gain;
    }

    function abondPaid()
      public view override
    returns (uint256)
    {
        uint256 ts = block.timestamp * EXP_SCALE;
        if (ts <= abond.issuedAt || (abond.maturesAt <= abond.issuedAt)) {
          return 0;
        }

        uint256 duration = abond.maturesAt.sub(abond.issuedAt);
        uint256 paidDuration = MathUtils.min(ts.sub(abond.issuedAt), duration);
        // abondGain() * paidDuration / duration
        return abondGain().mul(paidDuration).div(duration);
    }

    function abondDebt()
      public view override
    returns (uint256)
    {
        // abondGain() - abondPaid()
        return abondGain().sub(abondPaid());
    }

  // /publics

  // internals

    // liquidates junior bonds up to upUntilTimestamp_ timestamp
    function _beforeProviderOp(uint256 upUntilTimestamp_) internal {
      // this modifier will be added to the begginging of all (write) functions.
      // The first tx after a queued liquidation's timestamp will trigger the liquidation
      // reducing the jToken supply, and setting aside owed_dai for withdrawals
      for (uint256 i = juniorBondsMaturitiesPrev; i < juniorBondsMaturities.length; i++) {
          if (upUntilTimestamp_ >= juniorBondsMaturities[i]) {
              _liquidateJuniorsAt(juniorBondsMaturities[i]);
              juniorBondsMaturitiesPrev = i.add(1);
          } else {
              break;
          }
      }
    }

    function _liquidateJuniorsAt(uint256 timestamp_)
      internal
    {
        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[timestamp_];

        require(
          jBondsAt.tokens > 0,
          "SY: nothing to liquidate"
        );

        require(
          jBondsAt.price == 0,
          "SY: already liquidated"
        );

        jBondsAt.price = price();

        // ---

        // underlyingLiquidatedJuniors += jBondsAt.tokens * jBondsAt.price / EXP_SCALE;
        underlyingLiquidatedJuniors = underlyingLiquidatedJuniors.add(
          jBondsAt.tokens.mul(jBondsAt.price).div(EXP_SCALE)
        );
        _burn(address(this), jBondsAt.tokens); // burns Junior locked tokens reducing the jToken supply
        tokensInJuniorBonds = tokensInJuniorBonds.sub(jBondsAt.tokens);
    }

    // removes matured seniorBonds from being accounted in abond
    function unaccountBonds(uint256[] memory bondIds_)
      external override
    {
      uint256 currentTime = block.timestamp;

      for (uint256 f = 0; f < bondIds_.length; f++) {
        if (
            currentTime >= seniorBonds[bondIds_[f]].maturesAt &&
            seniorBonds[bondIds_[f]].liquidated == false
        ) {
            seniorBonds[bondIds_[f]].liquidated = true;
            _unaccountBond(seniorBonds[bondIds_[f]]);
        }
      }
    }

    function _mintBond(address to_, SeniorBond memory bond_)
      internal
    {
        require(
          seniorBondId < MAX_UINT256,
          "SY: _mintBond"
        );

        seniorBondId++;
        seniorBonds[seniorBondId] = bond_;
        _accountBond(bond_);
        IBond(seniorBond).mint(to_, seniorBondId);
    }

    // when a new bond is added to the pool, we want:
    // - to average abond.maturesAt (the earliest date at which juniors can fully exit), this shortens the junior exit date compared to the date of the last active bond
    // - to keep the price for jTokens before a bond is bought ~equal with the price for jTokens after a bond is bought
    function _accountBond(SeniorBond memory b_)
      internal
    {
        uint256 _now = block.timestamp * EXP_SCALE;

        //abondDebt() + b_.gain
        uint256 newDebt = abondDebt().add(b_.gain);
        // for the very first bond or the first bond after abond maturity: abondDebt() = 0 => newMaturesAt = b.maturesAt
        // (abond.maturesAt * abondDebt() + b_.maturesAt * EXP_SCALE * b_.gain) / newDebt
        uint256 newMaturesAt = (abond.maturesAt.mul(abondDebt()).add(b_.maturesAt.mul(EXP_SCALE).mul(b_.gain))).div(newDebt);

        // (uint256(1) + ((abond.gain + b_.gain) * (newMaturesAt - _now)) / newDebt)
        uint256 newDuration = (abond.gain.add(b_.gain)).mul(newMaturesAt.sub(_now)).div(newDebt).add(1);
        // timestamp = timestamp - tokens * d / tokens
        uint256 newIssuedAt = newMaturesAt.sub(newDuration, "SY: liquidate some seniorBonds");

        abond = SeniorBond(
          abond.principal.add(b_.principal),
          abond.gain.add(b_.gain),
          newIssuedAt,
          newMaturesAt,
          false
        );
    }

    // when a bond is redeemed from the pool, we want:
    // - for abond.maturesAt (the earliest date at which juniors can fully exit) to remain the same as before the redeem
    // - to keep the price for jTokens before a bond is bought ~equal with the price for jTokens after a bond is bought
    function _unaccountBond(SeniorBond memory b_)
      internal
    {
        uint256 now_ = block.timestamp * EXP_SCALE;

        if ((now_ >= abond.maturesAt)) {
          // abond matured
          // abondDebt() == 0
          abond = SeniorBond(
            abond.principal.sub(b_.principal),
            abond.gain - b_.gain,
            now_.sub(abond.maturesAt.sub(abond.issuedAt)),
            now_,
            false
          );

          return;
        }
        // uint256(1) + (abond.gain - b_.gain) * (abond.maturesAt - now_) / abondDebt()
        uint256 newDuration = (abond.gain.sub(b_.gain)).mul(abond.maturesAt.sub(now_)).div(abondDebt()).add(1);
        // timestamp = timestamp - tokens * d / tokens
        uint256 newIssuedAt = abond.maturesAt.sub(newDuration, "SY: liquidate some seniorBonds");

        abond = SeniorBond(
          abond.principal.sub(b_.principal),
          abond.gain.sub(b_.gain),
          newIssuedAt,
          abond.maturesAt,
          false
        );
    }

    function _mintJuniorBond(address to_, JuniorBond memory jb_)
      internal
    {
        require(
          juniorBondId < MAX_UINT256,
          "SY: _mintJuniorBond"
        );

        juniorBondId++;
        juniorBonds[juniorBondId] = jb_;

        _accountJuniorBond(jb_);
        IBond(juniorBond).mint(to_, juniorBondId);
    }

    function _accountJuniorBond(JuniorBond memory jb_)
      internal
    {
        // tokensInJuniorBonds += jb_.tokens
        tokensInJuniorBonds = tokensInJuniorBonds.add(jb_.tokens);

        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[jb_.maturesAt];
        uint256 tmp;

        if (jBondsAt.tokens == 0 && block.timestamp < jb_.maturesAt) {
          juniorBondsMaturities.push(jb_.maturesAt);
          for (uint256 i = juniorBondsMaturities.length - 1; i >= MathUtils.max(1, juniorBondsMaturitiesPrev); i--) {
            if (juniorBondsMaturities[i] > juniorBondsMaturities[i - 1]) {
              break;
            }
            tmp = juniorBondsMaturities[i - 1];
            juniorBondsMaturities[i - 1] = juniorBondsMaturities[i];
            juniorBondsMaturities[i] = tmp;
          }
        }

        // jBondsAt.tokens += jb_.tokens
        jBondsAt.tokens = jBondsAt.tokens.add(jb_.tokens);
    }

    function _burnJuniorBond(uint256 bondId_) internal {
        // blows up if already burned
        IBond(juniorBond).burn(bondId_);
    }

    function _unaccountJuniorBond(JuniorBond memory jb_) internal {
        // tokensInJuniorBonds -= jb_.tokens;
        tokensInJuniorBonds = tokensInJuniorBonds.sub(jb_.tokens);
        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[jb_.maturesAt];
        // jBondsAt.tokens -= jb_.tokens;
        jBondsAt.tokens = jBondsAt.tokens.sub(jb_.tokens);
    }

    function _takeTokens(address from_, uint256 amount_) internal {
        _transfer(from_, address(this), amount_);
    }

  // /internals

}