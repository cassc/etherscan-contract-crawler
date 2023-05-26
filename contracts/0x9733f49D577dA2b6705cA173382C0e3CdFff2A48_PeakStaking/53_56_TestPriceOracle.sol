pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../interfaces/PriceOracle.sol";
import "../interfaces/CERC20.sol";

contract TestPriceOracle is PriceOracle, Ownable {
  using SafeMath for uint;

  uint public constant PRECISION = 10 ** 18;
  address public CETH_ADDR;

  mapping(address => uint256) public priceInUSD;

  constructor(address[] memory _tokens, uint256[] memory _pricesInUSD, address _cETH) public {
    for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
      priceInUSD[_tokens[i]] = _pricesInUSD[i];
    }
    CETH_ADDR = _cETH;
  }

  function setTokenPrice(address _token, uint256 _priceInUSD) public onlyOwner {
    priceInUSD[_token] = _priceInUSD;
  }

  function getUnderlyingPrice(address _cToken) external view returns (uint) {
    if (_cToken == CETH_ADDR) {
      return priceInUSD[_cToken];
    }
    CERC20 cToken = CERC20(_cToken);
    ERC20Detailed underlying = ERC20Detailed(cToken.underlying());
    return priceInUSD[_cToken].mul(PRECISION).div(10 ** uint256(underlying.decimals()));
  }
}