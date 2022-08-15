pragma solidity >=0.6.0 <0.8.0;
import { ArbitrumConvertLib } from "./ArbitrumConvertLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract ArbitrumConvert is IZeroModule {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => ArbitrumConvertLib.ConvertRecord) public outstanding;
  address public immutable controller;
  address public immutable governance;
  uint256 public blockTimeout;
  address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant override want = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address public constant renCrvArbitrum = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
  address public constant tricryptoArbitrum = 0x960ea3e3C7FB317332d990873d354E18d7645590;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(address _controller) {
    controller = _controller;
    governance = IController(_controller).governance();
    IERC20(want).safeApprove(renCrvArbitrum, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricryptoArbitrum, ~uint256(0) >> 2);
  }

  function setBlockTimeout(uint256 _ct) public {
    require(msg.sender == governance, "!governance");
    blockTimeout = _ct;
  }

  function isActive(ArbitrumConvertLib.ConvertRecord storage record) internal view returns (bool) {
    return record.qty != 0 || record.qtyETH != 0;
  }

  function defaultLoan(uint256 _nonce) public {
    require(block.number >= outstanding[_nonce].when + blockTimeout);
    require(isActive(outstanding[_nonce]), "!outstanding");
    uint256 _amountSwappedBack = swapTokensBack(outstanding[_nonce]);
    IERC20(want).safeTransfer(controller, _amountSwappedBack);
    delete outstanding[_nonce];
  }

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    uint256 ratio = abi.decode(_data, (uint256));
    (uint256 amountSwappedETH, uint256 amountSwappedBTC) = swapTokens(_actual, ratio);
    outstanding[_nonce] = ArbitrumConvertLib.ConvertRecord({
      qty: amountSwappedBTC,
      when: uint64(block.timestamp),
      qtyETH: amountSwappedETH
    });
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

  function swapTokensBack(ArbitrumConvertLib.ConvertRecord storage record) internal returns (uint256 amountReturned) {
    uint256 _amountStart = IERC20(wbtc).balanceOf(address(this));
    (bool success, ) = tricryptoArbitrum.call{ value: record.qtyETH }(
      abi.encodeWithSelector(ICurveETHUInt256.exchange.selector, 2, 1, record.qtyETH, 0, true)
    );
    require(success, "!exchange");
    uint256 wbtcOut = IERC20(wbtc).balanceOf(address(this));
    amountReturned = IRenCrvArbitrum(renCrvArbitrum).exchange(0, 1, wbtcOut, 0, address(this)).add(record.qty);
  }

  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    require(outstanding[_nonce].qty != 0 || outstanding[_nonce].qtyETH != 0, "!outstanding");
    IERC20(want).safeTransfer(_to, outstanding[_nonce].qty);
    address payable to = address(uint160(_to));
    to.transfer(outstanding[_nonce].qtyETH);
    delete outstanding[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view override returns (uint256) {
    return _in.mul(uint256(1e17)).div(uint256(1 ether));
  }
}