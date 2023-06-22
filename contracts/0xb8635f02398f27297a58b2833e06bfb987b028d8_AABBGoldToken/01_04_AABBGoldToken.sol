pragma solidity ^0.7.0;

import "./AbstractToken.sol";

/**
 * AABB Gold token smart contract.
 */
contract AABBGoldToken is AbstractToken {
  uint256 tokenCount;

  /**
   * Create new AABB Gold token smart contract, with given number of tokens issued
   * and given to msg.sender.
   *
   * @param _tokenCount number of tokens to issue and give to msg.sender
   */
  constructor (uint256 _tokenCount) {
    accounts [msg.sender] = _tokenCount;
    tokenCount = _tokenCount;
  }

  /**
   * Get total number of tokens in circulation.
   *
   * @return supply total number of tokens in circulation
   */
  function totalSupply () override public view returns (uint256 supply) {
    return tokenCount;
  }

  /**
   * Get name of this token.
   *
   * @return result name of this token
   */
  function name () public pure returns (string memory result) {
    return "AABB Gold";
  }

  /**
   * Get symbol of this token.
   *
   * @return result symbol of this token
   */
  function symbol () public pure returns (string memory result) {
    return "AABBG";
  }

  /**
   * Get number of decimals for this token.
   *
   * @return result number of decimals for this token
   */
  function decimals () public pure returns (uint8 result) {
    return 8;
  }

  /**
   * Change how many tokens given spender is allowed to transfer from message
   * spender.  In order to prevent double spending of allowance, this method
   * receives assumed current allowance value as an argument.  If actual
   * allowance differs from an assumed one, this method just returns false.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _currentValue assumed number of tokens currently allowed to be
   *        transferred
   * @param _newValue number of tokens to allow to transfer
   * @return success true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _currentValue, uint256 _newValue)
    public returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }
}

