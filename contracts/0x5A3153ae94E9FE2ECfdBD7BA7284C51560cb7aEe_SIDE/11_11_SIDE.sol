// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract SIDE is ERC20, AccessControl {
  bytes32 public constant DEV = keccak256('DEV');
  uint256 public TOTAL_SUPPLY = 5_800_000_000e18;

  address public dev;
  mapping(address => bool) private _blacklisted;

  // Used to launch the token. Cannot swap until this is set to true. Cannot be set to false after launch
  bool public allowTrading = false;

  constructor() ERC20('Side', 'SIDE') {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    grantRole(DEV, msg.sender);
    dev = msg.sender;

    _mint(msg.sender, TOTAL_SUPPLY);
  }

  receive() external payable {}

  // Standard ERC20 _beforeTokenTransfer function with a blacklist system & allow trading
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override(ERC20) {
    // Safety checks
    require(!isBlacklisted(_from), 'Sender is blacklisted; cannot proceed with transfer');
    require(!isBlacklisted(_to), 'Recipient is blacklisted; cannot proceed with transfer');
    require(allowTrading || _from == dev || _from == address(0), 'Trading has not started yet');

    // Transfer
    super._beforeTokenTransfer(_from, _to, _amount);
  }

  // Allows access to the "_blacklisted" array
  function isBlacklisted(address _user) public view returns (bool) {
    return _blacklisted[_user];
  }

  // Withdraws an amount of ETH stored on the contract
  function withdrawDev(uint256 _amount) external onlyRole(DEV) {
    payable(msg.sender).transfer(_amount);
  }

  // Withdraws an amount of ERC20 tokens stored on the contract
  function withdrawERC20Dev(address _erc20, uint256 _amount) external onlyRole(DEV) {
    IERC20(_erc20).transfer(msg.sender, _amount);
  }

  function changeDev(address _dev) external onlyRole(DEV) {
    revokeRole(DEV, dev);
    grantRole(DEV, _dev);
    dev = _dev;
  }

  function revokeDev(address _devToRevoke) external onlyRole(DEV) {
    revokeRole(DEV, _devToRevoke);
  }

  function blacklistDev(address _account, bool _isBlacklisted) external onlyRole(DEV) {
    _blacklisted[_account] = _isBlacklisted;
  }

  function startTradingDev() external onlyRole(DEV) {
    allowTrading = true;
  }
}