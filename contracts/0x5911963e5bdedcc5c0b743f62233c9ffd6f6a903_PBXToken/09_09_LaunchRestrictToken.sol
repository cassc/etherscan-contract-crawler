pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract LaunchRestrictToken is Ownable {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => bool) private _openSender;
  bool public locked = true;

  function addSender(address account) external onlyOwner {
    _openSender[account] = true;
  }

  function unlockTokens() external onlyOwner {
    locked = false;
  }

  modifier launchRestrict(address sender) {
    if (locked) {
      require(_openSender[sender], "LaunchRestrict: transfers are disabled");
    }
    _;
  }
}