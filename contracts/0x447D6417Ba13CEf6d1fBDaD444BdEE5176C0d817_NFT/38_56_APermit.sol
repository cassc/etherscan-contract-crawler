// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { IERC20Permit } from '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

abstract contract APermit {
  struct PermitParameters {
    address token;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function _permitToken(PermitParameters memory _permitParams) internal {
    if (IERC20(_permitParams.token).allowance(_permitParams.owner, _permitParams.spender) < _permitParams.value) {
      IERC20Permit(_permitParams.token).permit(
        _permitParams.owner,
        _permitParams.spender,
        _permitParams.value,
        _permitParams.deadline,
        _permitParams.v,
        _permitParams.r,
        _permitParams.s
      );
    }
  }

  function _permitTokens(PermitParameters memory _permitParams0, PermitParameters memory _permitParams1) internal {
    _permitToken(_permitParams0);
    _permitToken(_permitParams1);
  }
}