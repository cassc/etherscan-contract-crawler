// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../zap/TokenZapLogic.sol";

abstract contract ZapGatewayBase is Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /// @notice Emitted when the zap logic contract is updated.
  /// @param _oldLogic The old logic address.
  /// @param _newLogic The new logic address.
  event UpdateLogic(address _oldLogic, address _newLogic);

  /// @notice The address of zap logic contract.
  address public logic;

  /// @dev Internal function to transfer token into this contract.
  /// @param _token The address of token to transfer.
  /// @param _amount The amount of token to transfer.
  function _transferTokenIn(address _token, uint256 _amount) internal returns (uint256) {
    if (_token == address(0)) {
      require(msg.value == _amount, "msg.value mismatch");
    } else {
      uint256 _balance = IERC20(_token).balanceOf(address(this));
      IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
      _amount = IERC20(_token).balanceOf(address(this)).sub(_balance);
    }

    return _amount;
  }

  /// @dev Internal function to do zap.
  /// @param _routes The routes to do zap. See comments in `TokenZapLogic` for more details.
  /// @param _amountIn The amount of input token.
  function _zap(uint256[] memory _routes, uint256 _amountIn) internal returns (uint256) {
    address _logic = logic;
    for (uint256 i = 0; i < _routes.length; i++) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool _success, bytes memory _result) = _logic.delegatecall(
        abi.encodeWithSelector(TokenZapLogic.swap.selector, _routes[i], _amountIn)
      );
      // below lines will propagate inner error up
      if (!_success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let ptr := mload(0x40)
          let size := returndatasize()
          returndatacopy(ptr, 0, size)
          revert(ptr, size)
        }
      }
      _amountIn = abi.decode(_result, (uint256));
    }
    return _amountIn;
  }

  /// @notice Update zap logic contract.
  /// @param _newLogic The address to update.
  function updateLogic(address _newLogic) external onlyOwner {
    address _oldLogic = logic;
    logic = _newLogic;

    emit UpdateLogic(_oldLogic, _newLogic);
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /// @notice Emergency function
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external payable onlyOwner returns (bool, bytes memory) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }
}