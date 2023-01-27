// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library SafeETH {

    event TransferETH(address indexed to, uint256 indexed value);

    function safeTransfer(address to, uint value) internal {
      (bool success, ) = to.call{ value: value }(new bytes(0));
      require(success, 'ETH transfer failed');
      emit TransferETH(to, value);
    }
}
