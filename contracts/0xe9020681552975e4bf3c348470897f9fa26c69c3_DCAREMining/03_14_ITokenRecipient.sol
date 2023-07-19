// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
abstract contract ITokenRecipient {
  /**
  * @dev Function that will handle incoming token transfers.
  *
  * @param _from  Token sender address.
  * @param _value Amount of tokens.
  * @param _data  Transaction metadata.
  */
  function tokenFallback(address _from, uint256 _value, bytes memory _data) public virtual returns (bool);
}