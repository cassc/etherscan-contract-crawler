pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

library TransferHelpers {
  using Address for address;

  function _safeTransferEther(address to, uint256 amount) internal returns (bool success) {
    (success, ) = to.call{value: amount}(new bytes(0));
    require(success, "failed to transfer ether");
  }

  function _safeTransferERC20(
    address token,
    address to,
    uint256 amount
  ) internal returns (bool success) {
    require(token.isContract(), "call_to_non_contract");
    (success, ) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes("transfer(address,uint256)"))), to, amount));
    require(success, "low_level_contract_call_failed");
  }

  function _safeTransferFromERC20(
    address token,
    address spender,
    address recipient,
    uint256 amount
  ) internal returns (bool success) {
    require(token.isContract(), "call_to_non_contract");
    (success, ) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes("transferFrom(address,address,uint256)"))), spender, recipient, amount));
    require(success, "low_level_contract_call_failed");
  }
}