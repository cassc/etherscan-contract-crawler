//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(address owner, address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
    transferOwnership(owner);
  }

  function updateTimeline(uint256 _start, uint256 _cliff, uint256 _duration) public onlyOwner {
    require(_cliff <= _duration);
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(IERC20 token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[address(token)] = released[address(token)].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(IERC20 token) public onlyOwner {
    require(revocable);
    require(!revoked[address(token)]);

    uint256 balance = token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[address(token)] = true;

    token.safeTransfer(owner(), refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(IERC20 token) public view returns (uint256) {
    return vestedAmount(token).sub(released[address(token)]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(IERC20 token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[address(token)]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[address(token)]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}