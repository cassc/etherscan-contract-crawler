// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../enums/CurrencyType.sol";

library TransferHelperV2 {
  function safeBalanceOf(address token, address owner) internal view returns (uint) {
    if (token == address(0))
      return address(owner).balance;

    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, owner));
    require(success, "TransferHelper: BALANCE_OF_FAILED");

    return abi.decode(data, (uint));
  }

  function safeOwnerOf(address token, uint tokenId) internal view returns (address) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x6352211e, tokenId));
    require(success, "TransferHelper: OWNER_OF_FAILED");

    return abi.decode(data, (address));
  }

  function safeApprove(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
  }

  function safeTransfer(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
  }

  function safeTransferETH(address to, uint value) internal {
    (bool success,) = to.call{value:value}(new bytes(0));
    require(success, "TransferHelper: TRANSFER_ETH_FAILED");
  }

  function safeTransferCurrency(CurrencyType currencyType, address token, address from, address to, uint value) internal returns (uint) {
    if (currencyType == CurrencyType.ETH) {
        safeTransferETH(to, value);
        return value;
    } else if (currencyType == CurrencyType.Token) {
        uint balanceBefore = safeBalanceOf(token, address(this));
        from == address(this) ? safeTransfer(token, to, value) : safeTransferFrom(token, from, to, value);
        uint balanceAfter = safeBalanceOf(token, address(this));
        return from == address(this) ? balanceBefore - balanceAfter : to == address(this) ? balanceAfter - balanceBefore : value;
    } else if (currencyType == CurrencyType.ERC721) {
        safeTransferFrom(token, from, to, value);
        return value;
    } else
        revert("TransferHelper: TRANSFER_CURRENCY_FAILED");
  }
}