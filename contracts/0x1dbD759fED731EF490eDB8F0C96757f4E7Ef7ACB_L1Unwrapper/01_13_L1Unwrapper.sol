// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "../helpers/OmnibridgeRouter.sol";

/// @dev Extension for original WETHOmnibridgeRouter that stores HorizonPool account registrations.
contract L1Unwrapper is OmnibridgeRouter {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // If this address sets to not zero it receives L1_fee.
  // It can be changed by the multisig.
  // And should implement fee sharing logic:
  // - some part to tx.origin - based on block base fee and can be subsidized
  // - store surplus of ETH for future subsidizions
  address payable public l1FeeReceiver;

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

  /**
   * @dev Bridged callback function used for unwrapping received tokens.
   * Can only be called by the associated Omnibridge contract.
   * @param _token bridged token contract address, should be WETH.
   * @param _value amount of bridged/received tokens.
   * @param _data extra data passed alongside with relayTokensAndCall on the other side of the bridge.
   * Should contain coins receiver address and L1 executer fee amount.
   */
  function onTokenBridged(
    address _token,
    uint256 _value,
    bytes memory _data
  ) external override {
    require(msg.sender == address(bridge), "only from bridge address");
    require(_data.length == 64, "incorrect data length");

    (address payable receipient, uint256 l1Fee) = abi.decode(_data, (address, uint256));

    if(_token == address(WETH)) {
        WETH.withdraw(_value);
        AddressHelper.safeSendValue(receipient, _value.sub(l1Fee));
    }
    else {
        IERC20(_token).transfer(receipient, _value.sub(l1Fee));
    }

    if (l1Fee > 0) {
      address payable l1FeeTo = l1FeeReceiver != payable(address(0)) ? l1FeeReceiver : payable(tx.origin);
      if(_token == address(WETH)) {
        AddressHelper.safeSendValue(l1FeeTo, l1Fee);
      }
      else {
        IERC20(_token).transfer(l1FeeTo, l1Fee);
      }
    }
  }

  /**
   * @dev Sets l1FeeReceiver address.
   * Only contract owner can call this method.
   * @param _receiver address of new L1FeeReceiver, address(0) for native tx.origin receiver.
   */
  function setL1FeeReceiver(address payable _receiver) external onlyOwner {
    l1FeeReceiver = _receiver;
  }
}