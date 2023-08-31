// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Staking } from "../governance/Staking.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title VestLock
 * @author Railgun Contributors
 * @notice Escrows vested tokens
 * @dev Designed to be used behing lightweight clones proxies
 */

contract VestLock is Initializable, OwnableUpgradeable {
  using SafeERC20 for IERC20;

  // Time to release tokens
  uint256 public releaseTime;

  // Staking contract
  Staking public staking;

  // Override key
  address public admin;

  // Lock functions until after releaseTime
  modifier locked() {
    require(block.timestamp > releaseTime, "VestLock: Vesting hasn't matured yet");
    _;
  }

  // Lock function unless called by admin
  modifier onlyAdmin() {
    require(msg.sender == admin, "VestLock: Caller not admin");
    _;
  }

  /**
   * @notice Initializes escrow contract
   * @dev Token must be railgun token, requires delegate function on token contract
   * @param _beneficiary - address to send tokens to at release time
   * @param _staking - Staking contract address
   * @param _releaseTime - time to release tokens
   */

  function initialize(
    address _admin,
    address _beneficiary,
    Staking _staking,
    uint256 _releaseTime
  ) external initializer {
    // Set admin
    admin = _admin;

    // Init OwnableUpgradeable
    OwnableUpgradeable.__Ownable_init();

    // Set beneficiary as owner
    OwnableUpgradeable.transferOwnership(_beneficiary);

    // Set the stacking contract
    staking = _staking;

    // Set release time
    releaseTime = _releaseTime;
  }

  /**
   * @notice Delegates stake
   * @param _id - id of stake to claim
   * @param _delegatee - address to delegate to
   */
  function delegate(uint256 _id, address _delegatee) public onlyOwner {
    staking.delegate(_id, _delegatee);
  }

  /**
   * @notice Stakes tokens
   * @param _token - address of the rail token
   * @param _amount - amount to stake
   */
  function stake(IERC20 _token, uint256 _amount) external onlyOwner {
    _token.safeApprove(address(staking), _amount);
    uint256 stakeID = staking.stake(_amount);
    staking.delegate(stakeID, OwnableUpgradeable.owner());
  }

  /**
   * @notice Unlocks tokens
   * @param _id - id of stake to unstake
   */
  function unlock(uint256 _id) external onlyOwner {
    staking.unlock(_id);
  }

  /**
   * @notice Claims tokens
   * @param _id - id of stake to claim
   */
  function claim(uint256 _id) external onlyOwner {
    staking.claim(_id);
  }

  /**
   * @notice Transfers ETH to specified address
   * @param _to - Address to transfer ETH to
   * @param _amount - Amount of ETH to transfer
   */
  function transferETH(address payable _to, uint256 _amount) external locked onlyOwner {
    _to.transfer(_amount);
  }

  /**
   * @notice Transfers ETH to specified address
   * @param _token - ERC20 token address to transfer
   * @param _to - Address to transfer tokens to
   * @param _amount - Amount of tokens to transfer
   */
  function transferERC20(IERC20 _token, address _to, uint256 _amount) external locked onlyOwner {
    _token.safeTransfer(_to, _amount);
  }

  /**
   * @notice Calls function
   * @dev calls to functions on arbitrary contracts
   * @param _contract - contract to call
   * @param _data - calldata to pass to contract
   * @param _value - ETH value to include in call
   */
  function callContract(address _contract, bytes calldata _data, uint256 _value) external locked onlyOwner {
    // Call external contract and return
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = _contract.call{value: _value}(_data);
    require(success, "VestLock: failure on external contract call");
  }

  /**
   * @notice Overrides vesting lock
   * @dev can only override to a lower value
   * @param _newLocktime - new lock time
   */
  function overrideLock(uint256 _newLocktime) external onlyAdmin {
    require(_newLocktime < releaseTime, "VestLock: new lock time must be less than old lock time");
    releaseTime = _newLocktime;
  }

  /**
   * @notice Recieve ETH
   */
  // solhint-disable-next-line no-empty-blocks
  fallback() external payable {}

  /**
   * @notice Receive ETH
   */
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}
}