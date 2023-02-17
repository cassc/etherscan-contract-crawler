// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

interface IMasterChefV1 {
  function withdraw(uint256 _pid, uint256 _amount) external;

  function deposit(uint256 _pid, uint256 _amount) external;
}

interface IBridgeAdapter {
  function bridge() external;

  function bridgeWithData(bytes calldata data) external;
}

/// @notice Contract to be inherited by implementation contract to provide methods for bridging Sushi to alternate networks
/// @dev Implementation must implement _bridge(bytes calldata data) method, data will be for most implementations 0x0 and not used
abstract contract BaseServer is Ownable {
  IMasterChefV1 public constant masterchefV1 = IMasterChefV1(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
  IERC20 public constant sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

  uint256 public immutable pid;
  address public immutable minichef;
  address public bridgeAdapter;
  uint256 public lastServe;

  event Harvested(uint256 indexed pid);
  event Withdrawn(uint256 indexed pid, uint256 indexed amount);
  event Deposited(uint256 indexed pid, uint256 indexed amount);
  event WithdrawnSushi(uint256 indexed pid, uint256 indexed amount);
  event WithdrawnDummyToken(uint256 indexed pid);
  event BridgeUpdated(address indexed newBridgeAdapter);
  event BridgedSushi(address indexed minichef, uint256 indexed amount); // make sure you fire event

  constructor(uint256 _pid, address _minichef) {
    pid = _pid;
    minichef = _minichef;
    bridgeAdapter = address(this);
  }

  // Perform harvest and bridge
  /// @dev harvests from MasterChefV1 and bridges to implemented network
  /// @param data bytes to be passed to _bridge(bytes calldata data) method, will be 0x0 for most
  function harvestAndBridge(bytes calldata data) public payable {
    masterchefV1.withdraw(pid, 0);
    bridge(data);
    emit Harvested(pid);
  }

  function harvest() public {
    masterchefV1.withdraw(pid, 0);
    emit Harvested(pid);
  }

  // Withdraw DummyToken from MasterChefV1
  /// @dev withdraws dummy token, used for harvesting Sushi, from MasterChefV1
  function withdraw() public onlyOwner {
    masterchefV1.withdraw(pid, 1);
    emit Withdrawn(pid, 1);
  }

  // Deposit DummyToken to MasterChefV1
  /// @dev deposits dummy token, used for harvesting Sushi, in MasterChefV1
  /// @param token address of dummy token to deposit
  function deposit(address token) public onlyOwner {
    IERC20(token).approve(address(masterchefV1), 1);
    masterchefV1.deposit(pid, 1);
    emit Deposited(pid, 1);
  }

  // Withdraw Sushi from this contract
  /// @dev withdraws Sushi from this contract
  /// @param recipient address to send withdrawn Sushi to
  function withdrawSushiToken(address recipient) public onlyOwner {
    uint256 sushiBalance = sushi.balanceOf(address(this));
    sushi.transfer(recipient, sushiBalance);
    emit WithdrawnSushi(pid, sushiBalance);
  }

  // Withdraw 1 unit of DummyToken from this contract
  /// @dev withdraws 1 unit of DummyToken from this contract
  /// @param token address of dummy token to withdraw
  /// @param recipient address to send withdrawn
  function withdrawDummyToken(address token, address recipient) public onlyOwner {
    IERC20(token).transfer(recipient, 1);
    emit WithdrawnDummyToken(pid);
  }

  // Update Bridge Adapter
  /// @dev updates or adds bridge adapter to update bridge call
  /// @param newBridgeAdapter address of new bridge adapter to set
  function updateBridgeAdapter(address newBridgeAdapter) public onlyOwner {
    require(newBridgeAdapter != address(0), "zero address");
    bridgeAdapter = newBridgeAdapter;
    emit BridgeUpdated(newBridgeAdapter);
  }

  // Bridge Sushi
  /// @dev bridges Sushi to alternate chain via implemented _bridge call
  /// @param data bytes to be passed to _bridge(bytes calldata data) method, will be 0x0 for most
  function bridge(bytes calldata data) public payable {
    if (bridgeAdapter == address(this)) {
      _bridge(data);
    } else {
      uint256 sushiBalance = sushi.balanceOf(address(this));
      sushi.transfer(bridgeAdapter, sushiBalance);
      IBridgeAdapter(bridgeAdapter).bridge();
    }
    lastServe = block.timestamp;
  }

  /// @dev virtual _bridge call to implement
  function _bridge(bytes calldata data) internal virtual;
}