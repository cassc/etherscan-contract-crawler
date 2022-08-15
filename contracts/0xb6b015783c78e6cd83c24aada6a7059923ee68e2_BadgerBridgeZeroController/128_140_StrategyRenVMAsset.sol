// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";

contract StrategyRenVMAsset {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public immutable want;

  address public weth;

  uint256 public performanceFee;
  uint256 public performanceMax;

  uint256 public withdrawalFee;
  uint256 public withdrawalMax;

  address public governance;
  address public controller;
  address public strategist;
  string public getName;

  constructor(
    address _controller,
    address _want,
    string memory _name
  ) {
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    want = _want;
    getName = _name;
  }

  function setStrategist(address _strategist) external {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external {
    require(msg.sender == governance, "!governance");
    withdrawalFee = _withdrawalFee;
  }

  function setPerformanceFee(uint256 _performanceFee) external {
    require(msg.sender == governance, "!governance");
    performanceFee = _performanceFee;
  }

  function deposit() public {
    uint256 _want = IERC20(want).balanceOf(msg.sender);
    IERC20(want).safeTransferFrom(address(msg.sender), address(this), _want);
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset) external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    require(want != address(_asset), "want");
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  function permissionedSend(address _target, uint256 _amount) external {
    require(msg.sender == controller, "!controller");
    IERC20(want).safeTransfer(_target, _amount);
  }

  // Withdraw partial funds, normally used with a vault withdrawal
  function withdraw(uint256 _amount) external {
    require(msg.sender == controller, "!controller");
    uint256 _balance = IERC20(want).balanceOf(address(this));
    if (_balance < _amount) {
      _amount = _withdrawSome(_amount.sub(_balance));
      _amount = _amount.add(_balance);
    }

    uint256 _fee = _amount.mul(withdrawalFee).div(withdrawalMax);

    IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

    IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
  }

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    _withdrawAll();

    balance = IERC20(want).balanceOf(address(this));

    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, balance);
  }

  function _withdrawAll() internal {
    _withdrawSome(balanceOfWant());
  }

  function harvest() public {
    require(msg.sender == strategist || msg.sender == governance, "!authorized");
  }

  function _withdrawC(uint256 _amount) internal {}

  function _withdrawSome(uint256 _amount) internal view returns (uint256) {
    uint256 _before = IERC20(want).balanceOf(address(this));
    uint256 _after = IERC20(want).balanceOf(address(this));
    uint256 _withdrew = _after.sub(_before);
    return _withdrew;
  }

  function balanceOfWant() public view returns (uint256 result) {
    result = IERC20(want).balanceOf(address(this));
  }

  function balanceOf() public view returns (uint256 result) {}

  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setController(address _controller) external {
    require(msg.sender == governance, "!governance");
    controller = _controller;
  }
}