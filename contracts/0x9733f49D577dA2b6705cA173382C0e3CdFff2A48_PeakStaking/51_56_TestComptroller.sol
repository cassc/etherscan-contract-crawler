pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/Comptroller.sol";
import "../interfaces/PriceOracle.sol";
import "../interfaces/CERC20.sol";

contract TestComptroller is Comptroller {
  using SafeMath for uint;

  uint256 internal constant PRECISION = 10 ** 18;

  mapping(address => address[]) public getAssetsIn;
  uint256 internal collateralFactor = 2 * PRECISION / 3;

  constructor() public {}

  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory) {
    uint[] memory errors = new uint[](cTokens.length);
    for (uint256 i = 0; i < cTokens.length; i = i.add(1)) {
      getAssetsIn[msg.sender].push(cTokens[i]);
      errors[i] = 0;
    }
    return errors;
  }

  function markets(address /*cToken*/) external view returns (bool isListed, uint256 collateralFactorMantissa) {
    return (true, collateralFactor);
  }
}