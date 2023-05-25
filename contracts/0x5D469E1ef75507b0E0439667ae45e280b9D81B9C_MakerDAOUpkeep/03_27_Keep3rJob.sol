// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Governable.sol';
import '../../interfaces/utils/IKeep3rJob.sol';
import '../../interfaces/external/IKeep3rV2.sol';
import '../../libraries/OracleLibrary.sol';


abstract contract Keep3rJob is IKeep3rJob, Governable {
  address public override keep3r = 0xdc02981c9C062d48a9bD54adBf51b816623dcc6E;
  address public override requiredBond = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
  uint256 public override requiredMinBond = 50 ether;
  uint256 public override requiredEarnings;
  uint256 public override requiredAge;
  address public override tokenWETHPool = 0x60594a405d53811d3BC4766596EFD80fd545A270;
  address public override baseToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public override quoteToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  uint256 public override boost = 120;
  uint32 public override twapTime = 300;

  function setKeep3r(address _keep3r) public override onlyGovernor {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) public override onlyGovernor {
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earned;
    requiredAge = _age;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age);
  }

  function setTokenWETHPool(address _tokenWETHPool) external override onlyGovernor {
    tokenWETHPool = _tokenWETHPool;
    emit TokenWETHPoolAddressSet(tokenWETHPool);
  }

  function setBaseToken(address _baseToken) external override onlyGovernor {
    baseToken = _baseToken;
    emit BaseTokenAddressSet(baseToken);
  }

  function setQuoteToken(address _quoteToken) external override onlyGovernor {
    quoteToken = _quoteToken;
    emit QuoteTokenAddressSet(quoteToken);
  }

  function setBoost(uint256 _boost) external override onlyGovernor {
    boost = _boost;
    emit BoostSet(_boost);
  }

  function setTwapTime(uint32 _twapTime) external override onlyGovernor {
    twapTime = _twapTime;
    emit TwapTimeSet(twapTime);
  }

  function _isValidKeeper(address _keeper) internal {
    if (!IKeep3rV2(keep3r).isBondedKeeper(_keeper, requiredBond, requiredMinBond, requiredEarnings, requiredAge)) revert KeeperNotValid();
  }

  modifier validateAndPayKeeper(address _keeper) {
    uint256 _initialGas = gasleft();
    _isValidKeeper(_keeper);
    _;
    try IKeep3rV2(keep3r).worked(_keeper) {} catch {
      int24 _twapTick = OracleLibrary.consult(tokenWETHPool, twapTime);
      uint256 _amount = OracleLibrary.getQuoteAtTick(
        _twapTick,
        uint128(((((_initialGas - gasleft()) * block.basefee * boost) / 100))),
        baseToken,
        quoteToken
      );
      IKeep3rV2(keep3r).directTokenPayment(quoteToken, _keeper, _amount);
    }
  }
}