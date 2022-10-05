// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./Pausable.sol";

contract Stablecoin is ERC20, Pausable, AccessControl {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  mapping (address => bool) private _isBlackListed;

  event DestroyedBlackFunds(address _blackListedUser, uint _balance);
  event AddedBlackList(address _user);
  event RemovedBlackList(address _user);

  constructor() ERC20("Duae Stablecoin", "DUAE") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }

  function getBlackListStatus(address _maker) external view returns (bool) {
    return _getBlackListStatus(_maker);
  } 

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  function redeem(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _redeem(amount);
  }
  
  function addBlackList (address _evilUser) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList (address _clearedUser) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  function destroyBlackFunds (address _blackListedUser) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_isBlackListed[_blackListedUser], "Stablecoin: user dont is in the blacklist");

    uint dirtyFunds = balanceOf(_blackListedUser);
    _destroyFundsAccount(_blackListedUser, dirtyFunds);
    emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
  }

  function _getBlackListStatus(address _maker) internal view returns (bool) {
    return _isBlackListed[_maker];
  } 

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    require(_getBlackListStatus(from) == false, "Stablecoin: impossible transfer because user is in the blacklist");
    super._beforeTokenTransfer(from, to, amount);
  }
  
}