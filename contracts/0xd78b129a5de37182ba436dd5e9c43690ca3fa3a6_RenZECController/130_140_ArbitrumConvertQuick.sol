pragma solidity >=0.6.0 <0.8.0;
import { ArbitrumConvertLib } from "./ArbitrumConvertLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";

contract ArbitrumConvertQuick {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => ArbitrumConvertLib.ConvertRecord) public outstanding;
  address public immutable controller;
  uint256 public blockTimeout;
  address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant want = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address public constant renCrvArbitrum = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
  address public constant tricryptoArbitrum = 0x960ea3e3C7FB317332d990873d354E18d7645590;
  uint256 public capacity;
  struct ConvertRecord {
    uint128 volume;
    uint128 when;
  }
  mapping(uint256 => ConvertRecord) public records;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  function governance() public view returns (address) {
    return IController(controller).governance();
  }

  function setBlockTimeout(uint256 _amount) public {
    require(msg.sender == governance(), "!governance");
    blockTimeout = _amount;
  }

  constructor(
    address _controller,
    uint256 _capacity,
    uint256 _blockTimeout
  ) {
    controller = _controller;
    capacity = _capacity;
    blockTimeout = _blockTimeout;
    IERC20(want).safeApprove(renCrvArbitrum, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricryptoArbitrum, ~uint256(0) >> 2);
  }

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) public onlyController {
    uint256 ratio = abi.decode(_data, (uint256));
    (uint256 amountSwappedETH, uint256 amountSwappedBTC) = swapTokens(_actual, ratio);
    IERC20(want).safeTransfer(_to, amountSwappedBTC);
    address payable to = address(uint160(_to));
    to.transfer(amountSwappedETH);
    records[_nonce] = ConvertRecord({ volume: uint128(_actual), when: uint128(block.number) });
    capacity = capacity.sub(_actual);
  }

  function defaultLoan(uint256 _nonce) public {
    require(uint256(records[_nonce].when) + blockTimeout <= block.number, "!expired");
    capacity = capacity.sub(uint256(records[_nonce].volume));
    delete records[_nonce];
  }

  function swapTokens(uint256 _amountIn, uint256 _ratio)
    internal
    returns (uint256 amountSwappedETH, uint256 amountSwappedBTC)
  {
    uint256 amountToETH = _ratio.mul(_amountIn).div(uint256(1 ether));
    uint256 wbtcOut = amountToETH != 0
      ? IRenCrvArbitrum(renCrvArbitrum).exchange(1, 0, amountToETH, 0, address(this))
      : 0;
    if (wbtcOut != 0) {
      uint256 _amountStart = address(this).balance;
      (bool success, ) = tricryptoArbitrum.call(
        abi.encodeWithSelector(ICurveETHUInt256.exchange.selector, 1, 2, wbtcOut, 0, true)
      );
      require(success, "!exchange");
      amountSwappedETH = address(this).balance.sub(_amountStart);
      amountSwappedBTC = _amountIn.sub(amountToETH);
    } else {
      amountSwappedBTC = _amountIn;
    }
  }

  receive() external payable {
    // no-op
  }

  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _nonce,
    bytes memory _data
  ) public onlyController {
    capacity = capacity.add(records[_nonce].volume);
    delete records[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view returns (uint256) {
    return _in.mul(12e17).div(1e18); // 120% collateralized
  }
}