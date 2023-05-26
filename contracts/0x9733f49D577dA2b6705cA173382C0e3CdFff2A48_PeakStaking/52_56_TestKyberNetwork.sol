pragma solidity 0.5.17;

import "../interfaces/KyberNetwork.sol";
import "../Utils.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract TestKyberNetwork is KyberNetwork, Utils(address(0), address(0), address(0)), Ownable {
  mapping(address => uint256) public priceInUSDC;

  constructor(address[] memory _tokens, uint256[] memory _pricesInUSDC) public {
    for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
      priceInUSDC[_tokens[i]] = _pricesInUSDC[i];
    }
  }

  function setTokenPrice(address _token, uint256 _priceInUSDC) public onlyOwner {
    priceInUSDC[_token] = _priceInUSDC;
  }

  function setAllTokenPrices(address[] memory _tokens, uint256[] memory _pricesInUSDC) public onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
      priceInUSDC[_tokens[i]] = _pricesInUSDC[i];
    }
  }

  function getExpectedRate(ERC20Detailed src, ERC20Detailed dest, uint /*srcQty*/) external view returns (uint expectedRate, uint slippageRate) 
  {
    uint256 result = priceInUSDC[address(src)].mul(10**getDecimals(dest)).mul(PRECISION).div(priceInUSDC[address(dest)].mul(10**getDecimals(src)));
    return (result, result);
  }

  function tradeWithHint(
    ERC20Detailed src,
    uint srcAmount,
    ERC20Detailed dest,
    address payable destAddress,
    uint maxDestAmount,
    uint /*minConversionRate*/,
    address /*walletId*/,
    bytes calldata /*hint*/
  )
    external
    payable
    returns(uint)
  {
    require(calcDestAmount(src, srcAmount, dest) <= maxDestAmount);

    if (address(src) == address(ETH_TOKEN_ADDRESS)) {
      require(srcAmount == msg.value);
    } else {
      require(src.transferFrom(msg.sender, address(this), srcAmount));
    }

    if (address(dest) == address(ETH_TOKEN_ADDRESS)) {
      destAddress.transfer(calcDestAmount(src, srcAmount, dest));
    } else {
      require(dest.transfer(destAddress, calcDestAmount(src, srcAmount, dest)));
    }
    return calcDestAmount(src, srcAmount, dest);
  }

  function calcDestAmount(
    ERC20Detailed src,
    uint srcAmount,
    ERC20Detailed dest
  ) internal view returns (uint destAmount) {
    return srcAmount.mul(priceInUSDC[address(src)]).mul(10**getDecimals(dest)).div(priceInUSDC[address(dest)].mul(10**getDecimals(src)));
  }

  function() external payable {}
}