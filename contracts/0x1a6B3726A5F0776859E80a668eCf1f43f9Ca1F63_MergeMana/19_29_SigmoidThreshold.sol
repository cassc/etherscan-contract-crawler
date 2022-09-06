//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract SigmoidThreshold {
  using SafeMath for uint256;
  using SafeMath for uint64;

  struct CurveParams {
    uint256 _x;
    uint256 minX;
    uint256 maxX;
    uint256 minY;
    uint256 maxY;
  }

  uint256[23] private slots;

  constructor() {
    slots[0] = 1000000000000000000;
    slots[1] = 994907149075715143;
    slots[2] = 988513057369406817;
    slots[3] = 982013790037908452;
    slots[4] = 970687769248643639;
    slots[5] = 952574126822433143;
    slots[6] = 924141819978756551;
    slots[7] = 880797077977882314;
    slots[8] = 817574476193643651;
    slots[9] = 731058578630004896;
    slots[10] = 622459331201854593;
    slots[11] = 500000000000000000;
    slots[12] = 377540668798145407;
    slots[13] = 268941421369995104;
    slots[14] = 182425523806356349;
    slots[15] = 119202922022117574;
    slots[16] = 75858180021243560;
    slots[17] = 47425873177566788;
    slots[18] = 29312230751356326;
    slots[19] = 17986209962091562;
    slots[20] = 11486942630593183;
    slots[21] = 5092850924284857;
    slots[22] = 0;
  }

  function getY(CurveParams memory config) public view returns (uint256) {
    if (config._x <= config.minX) {
      return config.minY;
    }
    if (config._x >= config.maxX) {
      return config.maxY;
    }

    uint256 slotWidth = config.maxX.sub(config.minX).div(slots.length);
    uint256 xa = config._x.sub(config.minX).div(slotWidth);
    uint256 xb = Math.min(xa.add(1), slots.length.sub(1));

    uint256 slope = slots[xa].sub(slots[xb]).mul(1e18).div(slotWidth);
    uint256 wy = slots[xa].add(slope.mul(slotWidth.mul(xa)).div(1e18));

    uint256 percentage = 0;
    if (wy > slope.mul(config._x).div(1e18)) {
      percentage = wy.sub(slope.mul(config._x).div(1e18));
    } else {
      percentage = slope.mul(config._x).div(1e18).sub(wy);
    }

    uint256 result = config.minY.add(
      config.maxY.sub(config.minY).mul(percentage).div(1e18)
    );

    return config.maxY.sub(result); // inverse curve to be LOW => HIGH
  }
}