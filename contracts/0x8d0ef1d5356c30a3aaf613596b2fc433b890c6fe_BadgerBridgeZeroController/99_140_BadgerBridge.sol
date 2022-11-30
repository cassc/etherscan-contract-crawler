pragma solidity >=0.6.0 <0.8.0;
import { BadgerBridgeLib } from "./BadgerBridgeLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrv } from "../interfaces/CurvePools/IRenCrv.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract BadgerBridge is IZeroModule {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => BadgerBridgeLib.ConvertRecord) public outstanding;
  address public immutable controller;
  address public immutable governance;
  uint256 public blockTimeout;
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address public constant override want = wbtc;
  address public constant renCrv = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
  address public constant tricrypto = 0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(address _controller) {
    controller = _controller;
    governance = IController(_controller).governance();
    IERC20(want).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricrypto, ~uint256(0) >> 2);
  }

  function setBlockTimeout(uint256 _ct) public {
    require(msg.sender == governance, "!governance");
    blockTimeout = _ct;
  }

  function isActive(BadgerBridgeLib.ConvertRecord storage record) internal view returns (bool) {
    return record.qty != 0;
  }

  function defaultLoan(uint256 _nonce) public {
    require(block.number >= outstanding[_nonce].when + blockTimeout);
    require(isActive(outstanding[_nonce]), "!outstanding");
    uint256 _amountSwappedBack = outstanding[_nonce].qty;
    IERC20(want).safeTransfer(controller, _amountSwappedBack);
    delete outstanding[_nonce];
  }

  function receiveLoan(
    address _to,
    address, /* _asset */
    uint256 _actual,
    uint256 _nonce,
    bytes memory /* _data */
  ) public override onlyController {
    outstanding[_nonce] = BadgerBridgeLib.ConvertRecord({ qty: uint128(_actual), when: uint128(block.timestamp) });
  }

  receive() external payable {
    // no-op
  }

  function repayLoan(
    address _to,
    address, /* _asset */
    uint256, /* _actualAmount */
    uint256 _nonce,
    bytes memory /* _data */
  ) public override onlyController {
    require(outstanding[_nonce].qty != 0, "!outstanding");
    IERC20(want).safeTransfer(_to, outstanding[_nonce].qty);
    delete outstanding[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view override returns (uint256) {
    return _in.mul(uint256(1e17)).div(uint256(1 ether));
  }
}