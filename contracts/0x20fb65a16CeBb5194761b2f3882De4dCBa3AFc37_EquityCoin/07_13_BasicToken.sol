// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC20Basic.sol";
import "./SafeMath.sol";
import "./BalanceSheet.sol";


// Version of OpenZeppelin's BasicToken whose balances mapping has been replaced
// with a separate BalanceSheet contract. Most useful in combination with e.g.
// HasNoContracts because then it can relinquish its balance sheet to a new
// version of the token, removing the need to copy over balances.
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Claimable {
  using SafeMath for uint256;

  BalanceSheet public balances;

  uint256 totalSupply_;

  function setBalanceSheet(address sheet) external onlyOwner {
    balances = BalanceSheet(sheet);
    balances.claimOwnership();
  }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public virtual returns (bool) {
    transferAllArgs(msg.sender, _to, _value);
    return true;
  }

  function transferAllArgs(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    require(_from != address(0));
    require(_value <= balances.balanceOf(_from));

    // SafeMath.sub will throw if there is not enough balance.
    balances.subBalance(_from, _value);
    balances.addBalance(_to, _value);
    emit Transfer(_from, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  */
  function balanceOf(address _owner) public view virtual returns (uint256 balance) {
    return balances.balanceOf(_owner);
  }
}