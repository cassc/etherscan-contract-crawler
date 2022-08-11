pragma solidity >=0.6.0 <0.8.0;
import { ArbitrumConvertLib } from "./ArbitrumConvertLib.sol";
import { IZeroMeta } from "../interfaces/IZeroMeta.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";
import "hardhat/console.sol";

contract MetaExecutor is IZeroMeta {
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

  receive() external payable {
    // no-op
  }

  function receiveMeta(
    address from,
    address asset,
    uint256 nonce,
    bytes memory data
  ) public override onlyController {
    // stuff here
  }

  function repayMeta(uint256 value) public override onlyController {
    // stuff here
    console.log(IERC20(want).balanceOf(address(this)));
    IERC20(want).safeTransfer(controller, value);
    console.log(want, value);
  }

  function computeReserveRequirement(uint256 _in) external view returns (uint256) {
    return _in.mul(12e17).div(1e18); // 120% collateralized
  }
}