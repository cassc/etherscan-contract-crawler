//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Configurable} from "../utils/Configurable.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

contract Whitelist is AccessControl, Configurable, IWhitelist {
  // roles
  bytes32 public constant CAN_MANAGE_ROLE = keccak256("CAN MANAGE");

  // structs
  struct Member {
    address account;
    uint256 allowance; // zero allowance -> inf allowance
  }
  struct Whitelisted {
    uint256 allowance; // zero allowance -> not whitelisted
    uint256 used;
  }

  // storage
  mapping(address => Whitelisted) public members;
  address public sale;

  // events
  event AccountNotWhitelisted(address account);
  event NotEnoughAllowance(address account, uint256 allowance, uint256 amount);
  event WhitelistUpdated(uint256 created, uint256 updated, uint256 deleted);

  // errors
  error InvalidAccount(address account, uint8 i);
  error AccountAlreadyWhitelisted(address account);
  error AccountDoesNotExist(address account);
  error InvalidSender(address account);
  error UsedBiggerThanAllowance(address account, uint256 used, uint256 newAllowance);

  modifier onlySale() {
    address sender = msg.sender;
    if (sender != sale) {
      revert InvalidSender(sender);
    }
    _;
  }

  constructor(bytes memory arguments_) {
    // tx members
    address sender = tx.origin;

    // decode
    Member[] memory members_ = abi.decode(arguments_, (Member[]));

    for (uint8 i = 0; i < members_.length; i++) {
      // member
      Member memory member = members_[i];

      // check address
      if (member.account == address(0x0)) {
        revert InvalidAccount(member.account, i);
      }
      if (member.allowance == 0) {
        member.allowance = type(uint256).max;
      }

      members[member.account] = Whitelisted(member.allowance, 0);
    }

    // role setup
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    _setRoleAdmin(CAN_MANAGE_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(CAN_MANAGE_ROLE, sender);
  }

  function configure(address sale_)
    external
    onlyInState(State.UNCONFIGURED)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // storage
    sale = sale_;

    // state
    state = State.CONFIGURED;
  }

  function update(
    Member[] memory toCreate,
    Member[] memory toUpdate,
    address[] memory toDelete
  ) external onlyRole(CAN_MANAGE_ROLE) {
    // bulk create
    for (uint8 i = 0; i < toCreate.length; i++) {
      // create member if not exists
      Member memory member = toCreate[i];
      if (members[member.account].allowance != 0) {
        revert AccountAlreadyWhitelisted(member.account);
      }
      if (member.allowance == 0) {
        member.allowance = type(uint256).max;
      }

      // optional allowance, used 0
      members[member.account] = Whitelisted(member.allowance, 0);
    }

    // bulk update
    for (uint8 i = 0; i < toUpdate.length; i++) {
      // update member if exists
      Member memory member = toUpdate[i];
      if (members[member.account].allowance == 0) {
        revert AccountDoesNotExist(member.account);
      }

      // zero allowance in input is max allowance
      if (member.allowance == 0) {
        member.allowance = type(uint256).max;
      }

      // revert if allowance limited and smaller than used
      uint256 used = members[member.account].used;
      if (used > member.allowance) {
        revert UsedBiggerThanAllowance(member.account, used, member.allowance);
      }

      // allowance updated, preserve used
      members[member.account].allowance = member.allowance;
    }

    // bulk delete
    for (uint8 i = 0; i < toDelete.length; i++) {
      // delete member if exists
      address account = toDelete[i];
      if (members[account].allowance == 0) {
        revert AccountDoesNotExist(account);
      }

      // empty storage
      members[account] = Whitelisted(0, 0);
    }

    // event
    emit WhitelistUpdated(toCreate.length, toUpdate.length, toDelete.length);
  }

  function use(uint256 amount)
    external
    override
    onlyInState(State.CONFIGURED)
    onlySale
    returns (bool)
  {
    // tx.members
    address sender = tx.origin;

    // member
    Whitelisted memory whitelisted = members[sender];

    // not whitelisted
    if (whitelisted.allowance == 0) {
      emit AccountNotWhitelisted(sender);
      return false;
    }

    // limit not enough
    uint256 allowance = whitelisted.allowance;
    if (allowance < whitelisted.used + amount) {
      emit NotEnoughAllowance(sender, allowance, amount);
      return false;
    }

    // storage and return
    members[sender].used += amount;
    return true;
  }
}