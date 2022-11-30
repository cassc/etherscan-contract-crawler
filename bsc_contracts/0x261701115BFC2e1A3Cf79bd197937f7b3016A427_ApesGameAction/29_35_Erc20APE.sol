// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract Erc20APE is ERC20Upgradeable, OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;
  address[] public users;
  uint256 public ratio;
  address public team;
  uint256 public burnRatio;
  
  function initialize(string memory _name, string memory _symbol) initializer public {
    __ERC20_init(_name, _symbol);
    __Ownable_init();
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
    for(uint256 i=0;i<users.length;i++) {
      if(users[i] == recipient) {
        uint256 fee = amount.mul(ratio).div(10000);
        amount = amount.sub(fee);
        super._transfer(sender, team, fee);
      }
    }
    super._transfer(sender, recipient, amount);
  }

  function mint(address account, uint256 amount) external onlyOwner {
    return super._mint(account,amount);
  }

  function burn(uint256 amount) external {
    require(super.balanceOf(msg.sender) >= amount, "ERC20: burn amount exceeds balance");
    super._burn(_msgSender(), amount);
  }

  function insert(address _user) external onlyOwner {
    for(uint256 i=0;i<users.length;i++) {
      if(users[i] == _user) {
        return;
      }
    }
    users.push(_user);
  }

  function setRatio(uint256 _ratio) external onlyOwner {
    ratio = _ratio;
  }
  
  function setBurnRatio(uint256 _burnratio) external onlyOwner {
    burnRatio = _burnratio;
  }
  
  function setTeam(address _user) external onlyOwner {
    team = _user;
  }
}