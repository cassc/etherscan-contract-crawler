// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Authorizable is Ownable {
  mapping(address => bool) public authorized;

  modifier onlyAuthorized() {
    require(authorized[msg.sender], "UNAUTHORIZED: Sender is not authorized");
    _;
  }

  function transferOwnership(address newOwner)
    public
    virtual
    override
    onlyOwner
  {
    authorized[owner()] = false;
    super.transferOwnership(newOwner);
    authorized[newOwner] = true;
  }

  function authorize(address _user, bool _authorize) public onlyOwner {
    authorized[_user] = _authorize;
  }
}