// https://ctclub.com (CLUB)
// https://twitter.com/CTClubETH
// https://t.me/CTClubETH
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import './LockerV3.sol';
import './V3PriceHandler.sol';

contract CTClub is ERC20, V3PriceHandler {
  address constant V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  uint16 public constant USD_PER_PFP = 300;

  struct PFPRegistration {
    address user;
    string sourceImgUrl;
  }

  LockerV3 public liquidityLocker;
  PFPRegistration[] public pfps;

  event BuyPFP(address indexed owner, string imgUrl, uint256 idx);

  constructor() ERC20('CT Club', 'CLUB') {
    _mint(_msgSender(), 10_000_000_000 * 10 ** 18);
    liquidityLocker = new LockerV3();
    liquidityLocker.transferOwnership(_msgSender());
  }

  function burn(uint256 _amount) external {
    _burn(_msgSender(), _amount);
  }

  function buyPFP(string memory imgUrl) external {
    _burn(_msgSender(), tokenPricePerPFP());
    pfps.push(PFPRegistration({ user: _msgSender(), sourceImgUrl: imgUrl }));
    emit BuyPFP(_msgSender(), imgUrl, pfps.length - 1);
  }

  function tokenPricePerPFP() public view returns (uint256) {
    uint256 _usdPerPFPX96 = USD_PER_PFP * FixedPoint96.Q96;
    return
      (_usdPerPFPX96 * 10 ** decimals()) / _getUSDPriceX96(_getPrimaryV3Pool());
  }

  function getNumPFPs() external view returns (uint256) {
    return pfps.length;
  }

  function _getPrimaryV3Pool() internal view returns (address) {
    (address token0, address token1) = address(this) < WETH9
      ? (address(this), WETH9)
      : (WETH9, address(this));
    PoolAddress.PoolKey memory _key = PoolAddress.PoolKey({
      token0: token0,
      token1: token1,
      fee: 10000
    });
    return PoolAddress.computeAddress(V3_FACTORY, _key);
  }
}