// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../interfaces/IConcentratorStrategy.sol";

// solhint-disable reason-string
// solhint-disable no-empty-blocks

abstract contract ConcentratorStrategyBase is IConcentratorStrategy, Initializable {
  using SafeERC20 for IERC20;

  /// @notice The address of operator.
  address public operator;

  /// @notice The list of rewards token.
  address[] public rewards;

  /// @dev reserved slots.
  uint256[48] private __gap;

  modifier onlyOperator() {
    require(msg.sender == operator, "ConcentratorStrategy: only operator");
    _;
  }

  // fallback function to receive eth.
  receive() external payable {}

  function _initialize(address _operator, address[] memory _rewards) internal {
    _checkRewards(_rewards);

    operator = _operator;
    rewards = _rewards;
  }

  /// @inheritdoc IConcentratorStrategy
  function updateRewards(address[] memory _rewards) public virtual override onlyOperator {
    _checkRewards(_rewards);

    delete rewards;
    rewards = _rewards;
  }

  /// @inheritdoc IConcentratorStrategy
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external payable override onlyOperator returns (bool, bytes memory) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }

  /// @inheritdoc IConcentratorStrategy
  function prepareMigrate(address _newStrategy) external virtual override onlyOperator {}

  /// @inheritdoc IConcentratorStrategy
  function finishMigrate(address _newStrategy) external virtual override onlyOperator {}

  /// @dev Internal function to validate rewards list.
  /// @param _rewards The address list of reward tokens.
  function _checkRewards(address[] memory _rewards) internal pure {
    for (uint256 i = 0; i < _rewards.length; i++) {
      require(_rewards[i] != address(0), "ConcentratorStrategy: zero reward token");
      for (uint256 j = 0; j < i; j++) {
        require(_rewards[i] != _rewards[j], "ConcentratorStrategy: duplicated reward token");
      }
    }
  }

  function _transferTokenBack(address _token, uint256 _amount) internal {
    // 2. transfer intermediate token back to operator.
    if (_token == address(0)) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool _success, ) = msg.sender.call{ value: _amount }("");
      require(_success, "ConcentratorStrategy: transfer ETH failed");
    } else {
      IERC20(_token).safeTransfer(msg.sender, _amount);
    }
  }
}