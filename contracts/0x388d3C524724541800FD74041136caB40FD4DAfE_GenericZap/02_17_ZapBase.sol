pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWeth.sol";

abstract contract ZapBase is Ownable {
  using SafeERC20 for IERC20;

  bool public paused;
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint256 internal constant DEADLINE = 0xf000000000000000000000000000000000000000000000000000000000000000;

  // fromToken => swapTarget (per curve, univ2 and balancer) approval status
  mapping(address => mapping(address => bool)) public approvedTargets;

  event SetContractState(bool paused);

  receive() external payable {
    require(msg.sender != tx.origin, "ZapBase: Do not send ETH directly");
  }

  /**
    @notice Adds or removes an approved swapTarget
    * swapTargets should be Zaps and must not be tokens!
    @param _tokens An array of tokens
    @param _targets An array of addresses of approved swapTargets
    @param _isApproved An array of booleans if target is approved or not
    */
  function setApprovedTargets(
    address[] calldata _tokens,
    address[] calldata _targets,
    bool[] calldata _isApproved
  ) external onlyOwner {
    uint256 _length = _isApproved.length;
    require(_targets.length == _length && _tokens.length == _length, "ZapBase: Invalid Input length");

    for (uint256 i = 0; i < _length; i++) {
      approvedTargets[_tokens[i]][_targets[i]] = _isApproved[i];
    }
  }

  /**
    @notice Toggles the contract's active state
     */
  function toggleContractActive() external onlyOwner {
    paused = !paused;

    emit SetContractState(paused);
  }

  function _transferToken(IERC20 _token, address _to, uint256 _amount) internal {
    uint256 balance = _token.balanceOf(address(this));
    require(_amount <= balance, "ZapBase: not enough tokens");
    SafeERC20.safeTransfer(_token, _to, _amount);
  }

  /**
   * @notice Transfers tokens from msg.sender to this contract
   * @notice If native token, use msg.value
   * @notice For use with Zap Ins
   * @param token The ERC20 token to transfer to this contract (0 address if ETH)
   * @return Quantity of tokens transferred to this contract
     */
  function _pullTokens(
    address token,
    uint256 amount
  ) internal returns (uint256) {
    if (token == address(0)) {
      require(msg.value > 0, "ZapBase: No ETH sent");
      return msg.value;
    }

    require(amount > 0, "ZapBase: Invalid token amount");
    require(msg.value == 0, "ZapBase: ETH sent with token");

    SafeERC20.safeTransferFrom(
      IERC20(token),
      msg.sender,
      address(this),
      amount
    );

    return amount;
  }

  function _depositEth(
    uint256 _amount
  ) internal {
    require(
      _amount > 0 && msg.value == _amount,
      "ZapBase: Input ETH mismatch"
    );
    IWETH(WETH).deposit{value: _amount}();
  }

  // circuit breaker modifiers
  modifier whenNotPaused() {
    require(!paused, "ZapBase: Paused");
    _;
  }
}