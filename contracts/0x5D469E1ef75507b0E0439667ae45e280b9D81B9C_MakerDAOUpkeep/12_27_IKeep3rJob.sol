// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IKeep3rJob is IGovernable {
  // events
  event Keep3rSet(address _keep3r);
  event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age);
  event TokenPaymentAddressSet(address _newTokenPaymentAddress);
  event TokenWETHPoolAddressSet(address _newTokenWETHPool);
  event BaseTokenAddressSet(address _newBaseToken);
  event QuoteTokenAddressSet(address _newQuoteToken);
  event BoostSet(uint256 _newBoost);
  event TwapTimeSet(uint256 _twapTime);

  // errors
  error KeeperNotRegistered();
  error KeeperNotValid();

  // variables
  function keep3r() external view returns (address _keep3r);

  function requiredBond() external view returns (address _requiredBond);

  function requiredMinBond() external view returns (uint256 _requiredMinBond);

  function requiredEarnings() external view returns (uint256 _requiredEarnings);

  function requiredAge() external view returns (uint256 _requiredAge);

  function tokenWETHPool() external returns (address _tokenWETHPool);

  function baseToken() external returns (address _baseToken);

  function quoteToken() external returns (address _quoteToken);

  function boost() external returns (uint256 _boost);

  function twapTime() external returns (uint32 _twapTime);

  // methods
  function setKeep3r(address _keep3r) external;

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external;

  function setTokenWETHPool(address _tokenWETHPool) external;

  function setBaseToken(address _baseToken) external;

  function setQuoteToken(address _quoteToken) external;

  function setBoost(uint256 _boost) external;

  function setTwapTime(uint32 _twapTime) external;
}