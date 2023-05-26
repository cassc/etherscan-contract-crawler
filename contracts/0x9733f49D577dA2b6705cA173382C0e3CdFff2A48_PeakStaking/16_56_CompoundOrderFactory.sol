pragma solidity 0.5.17;

import "./LongCERC20Order.sol";
import "./LongCEtherOrder.sol";
import "./ShortCERC20Order.sol";
import "./ShortCEtherOrder.sol";
import "../lib/CloneFactory.sol";

contract CompoundOrderFactory is CloneFactory {
  address public SHORT_CERC20_LOGIC_CONTRACT;
  address public SHORT_CEther_LOGIC_CONTRACT;
  address public LONG_CERC20_LOGIC_CONTRACT;
  address public LONG_CEther_LOGIC_CONTRACT;

  address public USDC_ADDR;
  address payable public KYBER_ADDR;
  address public COMPTROLLER_ADDR;
  address public ORACLE_ADDR;
  address public CUSDC_ADDR;
  address public CETH_ADDR;

  constructor(
    address _shortCERC20LogicContract,
    address _shortCEtherLogicContract,
    address _longCERC20LogicContract,
    address _longCEtherLogicContract,
    address _usdcAddr,
    address payable _kyberAddr,
    address _comptrollerAddr,
    address _priceOracleAddr,
    address _cUSDCAddr,
    address _cETHAddr
  ) public {
    SHORT_CERC20_LOGIC_CONTRACT = _shortCERC20LogicContract;
    SHORT_CEther_LOGIC_CONTRACT = _shortCEtherLogicContract;
    LONG_CERC20_LOGIC_CONTRACT = _longCERC20LogicContract;
    LONG_CEther_LOGIC_CONTRACT = _longCEtherLogicContract;

    USDC_ADDR = _usdcAddr;
    KYBER_ADDR = _kyberAddr;
    COMPTROLLER_ADDR = _comptrollerAddr;
    ORACLE_ADDR = _priceOracleAddr;
    CUSDC_ADDR = _cUSDCAddr;
    CETH_ADDR = _cETHAddr;
  }

  function createOrder(
    address _compoundTokenAddr,
    uint256 _cycleNumber,
    uint256 _stake,
    uint256 _collateralAmountInUSDC,
    uint256 _loanAmountInUSDC,
    bool _orderType
  ) external returns (CompoundOrder) {
    require(_compoundTokenAddr != address(0));

    CompoundOrder order;

    address payable clone;
    if (_compoundTokenAddr != CETH_ADDR) {
      if (_orderType) {
        // Short CERC20 Order
        clone = toPayableAddr(createClone(SHORT_CERC20_LOGIC_CONTRACT));
      } else {
        // Long CERC20 Order
        clone = toPayableAddr(createClone(LONG_CERC20_LOGIC_CONTRACT));
      }
    } else {
      if (_orderType) {
        // Short CEther Order
        clone = toPayableAddr(createClone(SHORT_CEther_LOGIC_CONTRACT));
      } else {
        // Long CEther Order
        clone = toPayableAddr(createClone(LONG_CEther_LOGIC_CONTRACT));
      }
    }
    order = CompoundOrder(clone);
    order.init(_compoundTokenAddr, _cycleNumber, _stake, _collateralAmountInUSDC, _loanAmountInUSDC, _orderType,
      USDC_ADDR, KYBER_ADDR, COMPTROLLER_ADDR, ORACLE_ADDR, CUSDC_ADDR, CETH_ADDR);
    order.transferOwnership(msg.sender);
    return order;
  }

  function getMarketCollateralFactor(address _compoundTokenAddr) external view returns (uint256) {
    Comptroller troll = Comptroller(COMPTROLLER_ADDR);
    (, uint256 factor) = troll.markets(_compoundTokenAddr);
    return factor;
  }

  function tokenIsListed(address _compoundTokenAddr) external view returns (bool) {
    Comptroller troll = Comptroller(COMPTROLLER_ADDR);
    (bool isListed,) = troll.markets(_compoundTokenAddr);
    return isListed;
  }

  function toPayableAddr(address _addr) internal pure returns (address payable) {
    return address(uint160(_addr));
  }
}