// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "IERC20.sol";

library TransferHelper {
  function safeTransferFrom(address _token, address _from, address _to, uint256 _value) internal {
    require(_token.code.length > 0, 'Xfai: TRANSFERFROM_FAILED');
    (bool success, bytes memory data) = _token.call(
      abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'Xfai: TRANSFERFROM_FAILED');
  }

  function safeTransferETH(address _to, uint _value) internal {
    (bool success, ) = _to.call{value: _value}(new bytes(0));
    require(success, 'Xfai: ETH_TRANSFER_FAILED');
  }

  function safeTransfer(address _token, address _to, uint256 _value) internal {
    require(_token.code.length > 0, 'Xfai: TRANSFER_FAILED');
    (bool success, bytes memory data) = _token.call(
      abi.encodeWithSelector(IERC20.transfer.selector, _to, _value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'Xfai: TRANSFER_FAILED');
  }
}