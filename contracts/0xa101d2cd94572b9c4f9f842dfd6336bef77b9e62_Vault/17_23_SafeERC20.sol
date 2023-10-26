// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC20.sol";


library SafeERC20 {
  error ErrorSendingERC20(address _token, address _to, uint256 _amount, bytes _result);

  function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal {
    (bool success, bytes memory result) = address(_token).call(abi.encodeWithSelector(
      IERC20.transfer.selector,
      _to,
      _amount
    ));

    if (!success || !optionalReturnsTrue(result)) {
      revert ErrorSendingERC20(address(_token), _to, _amount, result);
    }
  }

  function optionalReturnsTrue(bytes memory _return) internal pure returns (bool) {
    return _return.length == 0 || abi.decode(_return, (bool));
  }
}