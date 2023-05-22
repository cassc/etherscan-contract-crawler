pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "./WithBlockedList.sol";

/*

   Copyright Tether.to 2020

   Author Will Harborne

   Licensed under the Apache License, Version 2.0
   http://www.apache.org/licenses/LICENSE-2.0

*/


contract TetherToken is Initializable, ERC20PermitUpgradeable, OwnableUpgradeable, WithBlockedList {

  // Unused variable retained to preserve storage slots across upgrades
  mapping(address => bool) public isTrusted;

  uint8 private tetherDecimals;

  function initialize(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) public initializer {
    tetherDecimals = _decimals;
    __Ownable_init();
    __ERC20_init(_name, _symbol);
    __ERC20Permit_init(_name);
  }

  function decimals() public view virtual override returns (uint8) {
      return tetherDecimals;
  }

  function transfer(address _recipient, uint256 _amount) public virtual override onlyNotBlocked returns (bool) {
    require(_recipient != address(this), "ERC20: transfer to the contract address");
    return super.transfer(_recipient, _amount);
  }

  function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override onlyNotBlocked returns (bool) {
    require(_recipient != address(this), "ERC20: transfer to the contract address");
    require(!isBlocked[_sender]);
    return super.transferFrom(_sender, _recipient, _amount);
  }

  function multiTransfer(address[] memory _recipients, uint256[] memory _values) public onlyNotBlocked {
    require(_recipients.length == _values.length , "ERC20: multiTransfer mismatch");
    for (uint256 i = 0; i < _recipients.length; i++) {
      transfer(_recipients[i], _values[i]);
    }
  }

  function mint(address _destination, uint256 _amount) public onlyOwner {
    _mint(_destination, _amount);
    emit Mint(_destination, _amount);
  }

  function redeem(uint256 _amount) public onlyOwner {
    _burn(owner(), _amount);
    emit Redeem(_amount);
  }

  function destroyBlockedFunds (address _blockedUser) public onlyOwner {
     require(isBlocked[_blockedUser]);
     uint blockedFunds = balanceOf(_blockedUser);
     _burn(_blockedUser, blockedFunds);
     emit DestroyedBlockedFunds(_blockedUser, blockedFunds);
 }

  event Mint(address indexed _destination, uint _amount);
  event Redeem(uint _amount);
  event DestroyedBlockedFunds(address indexed _blockedUser, uint _balance);

}