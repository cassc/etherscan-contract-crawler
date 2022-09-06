// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "omnibridge/contracts/helpers/WETHOmnibridgeRouter.sol";

/// @dev Extension for original WETHOmnibridgeRouter that stores TornadoPool account registrations.
contract L1Helper is WETHOmnibridgeRouter {
  event PublicKey(address indexed owner, bytes key);

  struct Account {
    address owner;
    bytes publicKey;
  }

  constructor(
    IOmnibridge _bridge,
    IWETH _weth,
    address _owner
  ) WETHOmnibridgeRouter(_bridge, _weth, _owner) {}

  /** @dev Registers provided public key and its owner in pool
   * @param _account pair of address and key
   */
  function register(Account memory _account) public {
    require(_account.owner == msg.sender, "only owner can be registered");
    _register(_account);
  }

  /**
   * @dev Wraps native assets and relays wrapped ERC20 tokens to the other chain.
   * It also calls receiver on other side with the _data provided.
   * @param _receiver bridged assets receiver on the other side of the bridge.
   * @param _data data for the call of receiver on other side.
   * @param _account tornadoPool account data
   */
  function wrapAndRelayTokens(
    address _receiver,
    bytes memory _data,
    Account memory _account
  ) public payable {
    WETH.deposit{ value: msg.value }();
    bridge.relayTokensAndCall(address(WETH), _receiver, msg.value, _data);

    if (_account.owner == msg.sender) {
      _register(_account);
    }
  }

  function _register(Account memory _account) internal {
    emit PublicKey(_account.owner, _account.publicKey);
  }
}