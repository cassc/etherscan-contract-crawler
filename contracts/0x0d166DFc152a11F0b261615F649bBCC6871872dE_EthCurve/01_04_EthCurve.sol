// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SignedWadMath.sol";

/** @title EthCurve Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract EthCurve is Ownable {
  bool public _initialized;
  uint256 public _count;
  uint256 public _decimals = 18;

  int256 public _posFeePercent18;
  int256 public _b18; //Min price, 18 decimals
  int256 public _L18; //Max price, 18 decimals
  int256 public _k18; //Slope, 18 decimals
  int256 public _m18; //Phase, 18 decimals

  uint256 public _lastReset;//block height of last reset
  uint256 public _resetInterval = 1;//100800;//number of 12second blocks in 2 weeks
  //int256 public _resetPriceMulitple;
  //int256 public _resetPriceThreshold;

  address public _BondingCurveAddress;


  modifier onlyBondingCurve() {
    require(msg.sender == _BondingCurveAddress, "only BC");
    _;
  }

  constructor() Ownable() {
    _lastReset = block.number;
  }

  function initialize(int256 L_, int256 k_, uint256 m_, int256 b_, int256 posPercent_) external onlyOwner() {
    require(!_initialized, "already");
    //Set default params
    _L18 = SignedWadMath.wadDiv(L_, 100);//1
    _k18 = SignedWadMath.wadDiv(k_, 10000);//0
    _m18 = SignedWadMath.toWadUnsafe(m_);//8888
    _b18 = SignedWadMath.wadDiv(b_, 1000);//0.065
    _posFeePercent18 = SignedWadMath.wadDiv(posPercent_, 100);//0.95

    //_resetPriceMulitple = SignedWadMath.wadDiv(resetPriceMultiple_, 100);//0.99
    //_resetPriceThreshold = SignedWadMath.wadMul(_resetPriceMulitple, _b18);

    /*TODO:un-uncomment*/
    //_initialized = true;
  }

  function setBondingCurve(address BondingCurveAddress_) external onlyOwner() {
    _BondingCurveAddress = BondingCurveAddress_;
  }


  function getPosFeePercent18() external view returns(int256){
    return _posFeePercent18;
  }

  function getCount() external view returns(uint256) {
    return _count;
  }


  function getNewReserve(int256 b18_, int256 posFeePercent18_) public view returns(uint256 newReserve) {
    //require reserveBalance >= newReserve == (b x supply) x (1 - pos)
    int256 oneMinusPos18 = SignedWadMath.toWadUnsafe(1) - posFeePercent18_;
    int256 bTimesSupply = SignedWadMath.wadMul(b18_, SignedWadMath.toWadUnsafe(_count));
    newReserve = uint256(SignedWadMath.wadMul(bTimesSupply, oneMinusPos18));
  }

  /**
   * Resets curve, updates params, and returns minimum reserve value.
   */
  function resetCurve(int256 k18_, int256 L18_, int256 b18_, int256 posFeePercent18_, uint256 _reserveBalance) external onlyBondingCurve returns(uint256 newReserve) {
    //require price is above threshold == resetPriceMulitple_ x _b18
    //_resetPriceThreshold = SignedWadMath.wadMul(_resetPriceMulitple, _b18);
    //require(getMintPrice(_count) >= uint256(_resetPriceThreshold), "insufficient price");

    //require time interval for reset
    uint256 blockInterval = block.number - _lastReset;
    require(blockInterval >= _resetInterval, "not yet");
    _lastReset = block.number;

    //require reserveBalance >= newReserve == (b x supply) x (1 - pos)
    //int256 oneMinusPos18 = SignedWadMath.toWadUnsafe(1) - _posFeePercent18;
    //int256 bTimesSupply = SignedWadMath.wadMul(b18_, SignedWadMath.toWadUnsafe(_count));
    //newReserve = uint256(SignedWadMath.wadMul(bTimesSupply, oneMinusPos18));
    newReserve = getNewReserve(b18_, posFeePercent18_);
    require(_reserveBalance >= newReserve, "Insuff reserve");

    //Reset can now proceed, all validations passed

    //calculate new m value
    //m = (ln[(L / b) - 1 ] + k * x) / k
    int256 kx18 = SignedWadMath.wadMul(k18_, SignedWadMath.toWadUnsafe(_count));
    int256 LOverB18 = SignedWadMath.wadDiv(L18_, b18_);
    int256 lnVar18 = LOverB18 - SignedWadMath.toWadUnsafe(1);
    int256 ln18 = SignedWadMath.wadLn(lnVar18);
    int256 numerator18 = ln18 + kx18;
    _m18 = SignedWadMath.wadDiv(numerator18, k18_);

    //update curve params
    _k18 = k18_;
    _L18 = L18_;
    _b18 = b18_;

    //_resetPriceMulitple = resetPriceMulitple_;
    //_resetPriceThreshold = SignedWadMath.wadMul(_resetPriceMulitple, _b18);
    _posFeePercent18 = posFeePercent18_;
  }

  function incrementCount(uint256 _amount) external onlyBondingCurve() {
    _count += _amount;
  }

  function decrementCount() external onlyBondingCurve() {
    _count--;
  }

  function getNextBurnReward() public view returns(uint256 reward) {
    return getBurnReward(_count);
  }

  //Must divide price by decimals to get value in ETH
  function getBurnReward(uint256 _x) public view returns(uint256 price) {
    uint256 mintPrice18 = getMintPrice(_x);

    int256 burnPercent18 = SignedWadMath.toWadUnsafe(1) - int256(_posFeePercent18);
    int256 burnPrice18 = SignedWadMath.wadMul(burnPercent18, int256(mintPrice18));

    return uint256(burnPrice18);
  }

  function getNextMintPrice() public view returns(uint256 price) {
    return getMintPrice(_count + 1);
  }

  //Must divide price by decimals to get value in ETH
  function getMintPrice(uint256 _x) public view returns(uint256 price) {
    // Formula: L / [1 + (1/e^(k * [x - m])) ]
    int256 x18 = SignedWadMath.toWadUnsafe(_x);
    int256 diff;
    int256 pow;
    int256 expo;

    if(x18 > _m18){//1/e
      diff = x18 - _m18;
      pow = SignedWadMath.wadMul(_k18, diff);
      expo = SignedWadMath.wadExp(pow);
      expo = SignedWadMath.wadDiv(SignedWadMath.toWadUnsafe(1), expo);
    }else{//e
      diff = _m18 - x18;
      pow = SignedWadMath.wadMul(_k18, diff);
      expo = SignedWadMath.wadExp(pow);
    }

    int256 denom = SignedWadMath.toWadUnsafe(1) + expo;
    int256 a = SignedWadMath.wadDiv(_L18, denom);

    price = uint256(_max(a, _b18));
  }

  function _max(int256 a, int256 b) internal pure returns (int256) {
    return a >= b ? a : b;
  }

}//end