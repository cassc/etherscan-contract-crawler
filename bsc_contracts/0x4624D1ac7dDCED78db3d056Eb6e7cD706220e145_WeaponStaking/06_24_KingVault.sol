// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./KingToken.sol";

contract KingVault is Initializable, AccessControlUpgradeable {

  bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

  KingToken public kingToken;

  mapping(address => uint256) public vaults;
  mapping(address => uint256) public claimed;

  function initialize(address kingAddress) public initializer {
    __AccessControl_init_unchained();
    _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
    _setupRole(GAME_ADMIN, tx.origin);

    kingToken = KingToken(kingAddress);
  }

  modifier restricted() {
    _restricted();
    _;
  }

  function _restricted() internal view {
    require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
  }

  function claimVault() external {
    require(vaults[msg.sender] > 0, "You don't have any king in the vault to claim");
    uint claimAmount = vaults[msg.sender];
    claimed[msg.sender] += claimAmount;
    vaults[msg.sender] = 0;
    kingToken.transfer(msg.sender, claimAmount);
  }

  function addToVault(address receiver, uint amount) restricted public {
    vaults[receiver] += amount;
  }

}