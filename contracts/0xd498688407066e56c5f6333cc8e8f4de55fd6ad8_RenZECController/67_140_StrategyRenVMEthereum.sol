// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IyVault.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IConverter.sol";
import { StrategyAPI } from "../interfaces/IStrategy.sol";
import { IController } from "../interfaces/IController.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract StrategyRenVMEthereum {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public immutable vault;
  address public immutable nativeWrapper;
  address public immutable want;
  int128 public constant wantIndex = 0;

  address public immutable vaultWant;
  int128 public constant vaultWantIndex = 1;

  string public constant name = "0confirmation RenVM Strategy";
  bool public constant isActive = true;

  uint256 public constant wantReserve = 1000000;
  uint256 public constant gasReserve = uint256(1e17);
  address public immutable controller;
  address public governance;
  address public strategist;

  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(
    address _controller,
    address _want,
    address _nativeWrapper,
    address _vault,
    address _vaultWant
  ) {
    nativeWrapper = _nativeWrapper;
    want = _want;
    vault = _vault;
    vaultWant = _vaultWant;
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    IERC20(_vaultWant).safeApprove(address(_vault), type(uint256).max);
  }

  receive() external payable {}

  function deposit() external virtual {
    //First conditional handles having too much of want in the Strategy
    uint256 _want = IERC20(want).balanceOf(address(this)); //amount of tokens we want
    if (_want > wantReserve) {
      // Then we can deposit excess tokens into the vault
      address converter = IController(controller).converters(want, vaultWant);
      require(converter != address(0x0), "!converter");
      uint256 _excess = _want.sub(wantReserve);
      require(IERC20(want).transfer(converter, _excess), "!transfer");
      uint256 _amountOut = IConverter(converter).convert(address(0x0));
      IyVault(vault).deposit(_amountOut);
    }
    //Second conditional handles having too little of gasWant in the Strategy

    uint256 _gasWant = address(this).balance; //ETH balance
    if (_gasWant < gasReserve) {
      // if ETH balance < ETH reserve
      _gasWant = gasReserve.sub(_gasWant);
      address _converter = IController(controller).converters(nativeWrapper, vaultWant);
      uint256 _vaultWant = IConverter(_converter).estimate(_gasWant); //_gasWant is estimated from wETH to wBTC
      uint256 _sharesDeficit = estimateShares(_vaultWant); //Estimate shares of wBTC
      // Works up to this point
      require(IERC20(vault).balanceOf(address(this)) > _sharesDeficit, "!enough"); //revert if shares needed > shares held
      uint256 _amountOut = IyVault(vault).withdraw(_sharesDeficit);
      address converter = IController(controller).converters(vaultWant, nativeWrapper);
      IERC20(vaultWant).transfer(converter, _amountOut);
      _amountOut = IConverter(converter).convert(address(this));
      address _unwrapper = IController(controller).converters(nativeWrapper, address(0x0));
      IERC20(nativeWrapper).transfer(_unwrapper, _amountOut);
      IConverter(_unwrapper).convert(address(this));
    }
  }

  function _withdraw(uint256 _amount, address _asset) private returns (uint256) {
    require(_asset == want || _asset == vaultWant, "asset not supported");
    if (_amount == 0) {
      return 0;
    }
    address converter = IController(controller).converters(want, vaultWant);
    // _asset is wBTC and want is renBTC
    if (_asset == want) {
      // if asset is what the strategy wants
      //then we can't directly withdraw it
      _amount = IConverter(converter).estimate(_amount);
    }
    uint256 _shares = estimateShares(_amount);
    _amount = IyVault(vault).withdraw(_shares);
    if (_asset == want) {
      // if asset is what the strategy wants
      IConverter toWant = IConverter(IController(controller).converters(vaultWant, want));
      IERC20(vaultWant).transfer(address(toWant), _amount);
      _amount = toWant.convert(address(0x0));
    }
    return _amount;
  }

  function permissionedEther(address payable _target, uint256 _amount) external virtual onlyController {
    // _amount is the amount of ETH to refund
    if (_amount > gasReserve) {
      _amount = IConverter(IController(controller).converters(nativeWrapper, vaultWant)).estimate(_amount);
      uint256 _sharesDeficit = estimateShares(_amount);
      uint256 _amountOut = IyVault(vault).withdraw(_sharesDeficit);
      address _vaultConverter = IController(controller).converters(vaultWant, nativeWrapper);
      address _converter = IController(controller).converters(nativeWrapper, address(0x0));
      IERC20(vaultWant).transfer(_vaultConverter, _amountOut);
      _amount = IConverter(_vaultConverter).convert(address(this));
      IERC20(nativeWrapper).transfer(_converter, _amount);
      _amount = IConverter(_converter).convert(address(this));
    }
    _target.transfer(_amount);
  }

  function withdraw(uint256 _amount) external virtual onlyController {
    IERC20(want).safeTransfer(address(controller), _withdraw(_amount, want));
  }

  function withdrawAll() external virtual onlyController {
    IERC20(want).safeTransfer(address(controller), _withdraw(IERC20(vault).balanceOf(address(this)), want));
  }

  function balanceOf() external view virtual returns (uint256) {
    return IyVault(vault).balanceOf(address(this));
  }

  function estimateShares(uint256 _amount) internal virtual returns (uint256) {
    return _amount.mul(10**IyVault(vault).decimals()).div(IyVault(vault).pricePerShare());
  }

  function permissionedSend(address _module, uint256 _amount) external virtual onlyController returns (uint256) {
    uint256 _reserve = IERC20(want).balanceOf(address(this));
    address _want = IZeroModule(_module).want();
    if (_amount > _reserve || _want != want) {
      _amount = _withdraw(_amount, _want);
    }
    IERC20(_want).safeTransfer(_module, _amount);
    return _amount;
  }
}