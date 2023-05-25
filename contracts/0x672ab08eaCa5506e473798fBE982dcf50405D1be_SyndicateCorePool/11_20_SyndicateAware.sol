// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../token/SyndicateERC20.sol";
import "../interfaces/ILinkedToSYN.sol";

/**
 * @title Syndicate Aware
 *        Original title: Illuvium Aware
 *
 * @notice Helper smart contract to be inherited by other smart contracts requiring to
 *      be linked to verified SyndicateERC20 instance and performing some basic tasks on it
 *
 * @author Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
abstract contract SyndicateAware is ILinkedToSYN {
  /// @dev Link to SYNR ERC20 Token SyndicateERC20 instance
  address public immutable override synr;

  /**
   * @dev Creates SyndicateAware instance, requiring to supply deployed SyndicateERC20 instance address
   *
   * @param _synr deployed SyndicateERC20 instance address
   */
  constructor(address _synr) {
    // verify SYNR address is set and is correct
    require(_synr != address(0), "SYNR address not set");
    require(
      SyndicateERC20(_synr).TOKEN_UID() == 0x83ecb176af7c4f35a45ff0018282e3a05a1018065da866182df12285866f5a2c,
      "unexpected TOKEN_UID"
    );

    // write SYNR address
    synr = _synr;
  }

  /**
   * @dev Executes SyndicateERC20.safeTransferFrom(address(this), _to, _value, "")
   *      on the bound SyndicateERC20 instance
   *
   * @dev Reentrancy safe due to the SyndicateERC20 design
   */
  function _transferSyn(address _to, uint256 _value) internal {
    // just delegate call to the target
    _transferSynFrom(address(this), _to, _value);
  }

  /**
   * @dev Executes SyndicateERC20.transferFrom(_from, _to, _value)
   *      on the bound SyndicateERC20 instance
   *
   * @dev Reentrancy safe due to the SyndicateERC20 design
   */
  function _transferSynFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal {
    // just delegate call to the target
    SyndicateERC20(synr).transferFrom(_from, _to, _value);
  }

  /**
   * @dev Executes SyndicateERC20.mint(_to, _values)
   *      on the bound SyndicateERC20 instance
   *
   * @dev Reentrancy safe due to the SyndicateERC20 design
   */
  function _mintSyn(address _to, uint256 _value) internal {
    // just delegate call to the target
    SyndicateERC20(synr).mint(_to, _value);
  }
}