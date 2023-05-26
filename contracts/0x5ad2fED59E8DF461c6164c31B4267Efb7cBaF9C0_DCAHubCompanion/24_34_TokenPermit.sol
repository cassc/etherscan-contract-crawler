// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

abstract contract TokenPermit {
  /**
   * @notice Executes a permit on a ERC20 token that supports it
   * @param _token The token that will execute the permit
   * @param _owner The account that signed the permite
   * @param _spender The account that is being approved
   * @param _value The amount that is being approved
   * @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permit(
    IERC20Permit _token,
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external payable {
    _token.permit(_owner, _spender, _value, _deadline, _v, _r, _s);
  }
}