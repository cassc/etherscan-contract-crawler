// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

interface ICurveTokenMinter {
  function token() external view returns (address);

  function controller() external view returns (address);

  function minted(address _user, address _gauge) external view returns (uint256);

  function allowed_to_mint_for(address _minter, address _user) external view returns (bool);

  function mint(address gauge_addr) external;

  function mint_many(address[8] memory gauge_addrs) external;

  function mint_for(address gauge_addr, address _for) external;

  function toggle_approve_mint(address minting_user) external;
}