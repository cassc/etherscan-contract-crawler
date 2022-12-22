/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐
 */
pragma solidity 0.6.12;

import "contracts/compound/Ownable.sol";

interface Oracle {
  function getUnderlyingPrice(address fToken) external view returns (uint256);

  function getAssetPrice(address asset) external view returns (uint256);
}

contract OndoPriceOracle is Ownable {
  mapping(address => uint256) public tokenToPrice;
  mapping(address => address) public fTokenToUnderlying;

  Oracle public oracle = Oracle(0x65c816077C29b557BEE980ae3cC2dCE80204A0C5);

  constructor(
    address _fCashAddress,
    address _fDaiAddress,
    address _cDaiAddress
  ) public Ownable() {
    tokenToPrice[_fCashAddress] = 1000000000000000000;
    fTokenToUnderlying[_fDaiAddress] = _cDaiAddress;
  }

  function getUnderlyingPrice(address fToken) public view returns (uint256) {
    address underlyingAddress = fTokenToUnderlying[fToken];
    if (underlyingAddress != address(0)) {
      return oracle.getUnderlyingPrice(underlyingAddress);
    } else {
      return tokenToPrice[fToken];
    }
  }

  function setCashOraclePrice(
    address fToken,
    uint256 value
  ) external onlyOwner {
    uint256 oldPrice = tokenToPrice[fToken];
    tokenToPrice[fToken] = value;
    emit CashPriceUpdated(oldPrice, value);
  }

  function setFTokenToUnderlying(
    address fToken,
    address underlying
  ) external onlyOwner {
    require(fToken != address(0), "FToken cannot have address 0");
    address oldUnderlying = fTokenToUnderlying[underlying];
    // note: address 0 is allowed here for underlying
    fTokenToUnderlying[fToken] = underlying;
    emit FTokenToUnderlyingSet(fToken, oldUnderlying, underlying);
  }

  function setOracle(address _newOracle) external onlyOwner {
    address oldOracle = address(oracle);
    oracle = Oracle(_newOracle);
    emit OracleUpdated(oldOracle, _newOracle);
  }

  event FTokenToUnderlyingSet(
    address indexed fToken,
    address oldUnderlying,
    address newUnderlying
  );
  event CashPriceUpdated(uint256 oldPrice, uint256 newPrice);
  event OracleUpdated(address oldOracle, address newOracle);
}