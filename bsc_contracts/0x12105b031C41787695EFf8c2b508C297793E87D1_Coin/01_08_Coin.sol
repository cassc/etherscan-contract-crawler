// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Coin is Initializable, ERC20Upgradeable, OwnableUpgradeable {
  address teamWallet;
  address deadWallet;
  uint teamFees;
  uint deadWalletFees;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() initializer public {
    __ERC20_init("GEG-E", "GEGE");
    __Ownable_init();

    _mint(msg.sender, 800000000 * 10 ** decimals());
  }

  function getTeamWallet() external view returns(address) {
    return teamWallet;
  }

  function setTeamWallet(address _teamWallet) external onlyOwner {
    teamWallet = _teamWallet;
  }

  function getDeadWallet() external view returns(address) {
    return deadWallet;
  }

  function setDeadWallet(address _deadWallet) external onlyOwner {
    deadWallet = _deadWallet;
  }

  function setTeamFees(uint _teamFees) external onlyOwner {
    teamFees = _teamFees;
  }

  function getTeamFees() external view returns(uint) {
    return teamFees;
  }

  function setDeadWalletFees(uint _deadWalletFees) external onlyOwner {
    deadWalletFees = _deadWalletFees;
  }

  function getDeadWalletFees() external view returns(uint) {
    return deadWalletFees;
  }

  function getTotalFees() internal view returns(uint) {
    uint totalFees = this.getDeadWalletFees() + this.getTeamFees();

    return totalFees;
  }

  function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
    uint teamFeesTotal = _amount * teamFees / 100;

    // Transfers 2% of the amount to the team
    _transfer(msg.sender, teamWallet, teamFeesTotal);

    uint deadWalletFeesTotal = _amount * deadWalletFees / 100;

    // Transfers 1% of the amount to send to the dead wallet
    _transfer(msg.sender, deadWallet, deadWalletFeesTotal);

    uint realTotal = _amount - teamFeesTotal - deadWalletFeesTotal;

    // Transfers the remaining 97% to _to
    _transfer(msg.sender, _to, realTotal);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
    address spender = _msgSender();

    _spendAllowance(_from, spender, _amount);
    
    uint teamFeesTotal = _amount * teamFees / 100;

    // Transfers 2% of the amount to the team
    _transfer(_from, teamWallet, teamFeesTotal);

    uint deadWalletFeesTotal = _amount * deadWalletFees / 100;

    // Transfers 1% of the amount to send to the dead wallet
    _transfer(_from, deadWallet, deadWalletFeesTotal);

    uint realTotal = _amount - teamFeesTotal - deadWalletFeesTotal;
    
    _transfer(_from, _to, realTotal);
    
    return true;
  }
}