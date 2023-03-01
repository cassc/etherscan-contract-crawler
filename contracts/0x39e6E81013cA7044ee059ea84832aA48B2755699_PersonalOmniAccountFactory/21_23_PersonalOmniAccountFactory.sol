pragma solidity >=0.8.0;

import {PersonalOmniAccount} from "./PersonalOmniAccount.sol";
import {TokenDelegate} from "./TokenDelegate.sol";

contract PersonalOmniAccountFactory {
  event AccountCreated(address account, address owner);

  function createAccount(address oracleAddress, TokenDelegate tokenDelegate) external returns (address) {
    return createAccountFor(msg.sender, oracleAddress, tokenDelegate);
  }

  function createAccountFor(address owner, address oracleAddress, TokenDelegate tokenDelegate) public returns (address) {
    PersonalOmniAccount account = new PersonalOmniAccount(oracleAddress, tokenDelegate);
    account.transferOwnership(owner);
    tokenDelegate.setAuthority(address(account), true);
    emit AccountCreated(address(account), owner);
    return address(account);
  }
}