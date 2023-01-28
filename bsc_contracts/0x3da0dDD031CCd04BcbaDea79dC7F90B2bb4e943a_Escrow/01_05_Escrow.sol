pragma solidity 0.5.16;

import "./openzeppelin/IERC20.sol";
import "./openzeppelin/SafeMath.sol";
import "./openzeppelin/Address.sol";
import "./openzeppelin//SafeERC20.sol";

contract Escrow {

  using SafeERC20 for IERC20;
  address public token;
  address public governance;

  modifier onlyGov() {
    require(msg.sender == governance, "only gov");
    _;
  }

  constructor (address _token) public {
    token = _token;
    governance = msg.sender;
  }

  function approve(address _token, address to, uint256 amount) public onlyGov {
    IERC20(_token).safeApprove(to, 0);
    IERC20(_token).safeApprove(to, amount);
  }

  function transfer(address _token, address to, uint256 amount) public onlyGov {
    IERC20(_token).safeTransfer(to, amount);
  }

  // This exists to mirror the interaction of how the perpetual staking pool would
  function notifySecondaryTokens(uint256 amount) external {
    IERC20(token).transferFrom(msg.sender, address(this), amount);
  }

  function setGovernance(address account) external onlyGov {
    governance = account;
  }
}