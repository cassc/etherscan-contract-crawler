// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "../helpers/OmnibridgeRouter.sol";

/// @dev Extension for original OmnibridgeRouter that stores HorizonPool account registrations.
contract L1Helper is OmnibridgeRouter {

  using SafeERC20 for IERC20;

  event PublicKey(address indexed owner, bytes key);

  struct Account {
    address owner;
    bytes publicKey;
  }

  constructor(
    IOmnibridge _bridge,
    IWETH _weth,
    address _owner
  ) OmnibridgeRouter(_bridge, _weth, _owner) {}

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
   * @param _account HorizonPool account data
   */
  function wrapAndRelayTokens(
    address _receiver,
    address token,
    uint256 amount,
    bytes memory _data,
    Account memory _account
  ) public payable {
    if(token == address(0)) {
        WETH.deposit{ value: msg.value }();
        bridge.relayTokensAndCall(address(WETH), _receiver, msg.value, _data);
    }
    else {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        bridge.relayTokensAndCall(token, _receiver, amount, _data);
    }

    if (_account.owner == msg.sender) {
      _register(_account);
    }
  }

  function _register(Account memory _account) internal {
    emit PublicKey(_account.owner, _account.publicKey);
  }
}