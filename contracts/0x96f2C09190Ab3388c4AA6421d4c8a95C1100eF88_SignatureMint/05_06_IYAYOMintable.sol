// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.19;

/**
  @custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
  @title A contract for minting new Ethereum-side YAYO tokens.
  @author cheb <evmcheb.eth>
  @author Tim Clancy <tim-clancy.eth>
  
  This token contract allows for privileged callers to mint new YAYO.

  @custom:date May 24th, 2023
*/
interface IYAYOMintable {

  /**
    A permissioned minting function. This function may only be called by the
    admin-specified minter.

    @param _to The recipient of the minted item.
    @param _tokenId The ID of the item to mint.
  */
  function mint (
    address _to,
    uint256 _tokenId
  ) external;
}