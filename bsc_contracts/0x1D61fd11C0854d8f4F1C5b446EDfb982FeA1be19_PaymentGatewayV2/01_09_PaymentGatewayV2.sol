// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

contract PaymentGatewayV2 is Initializable, OwnableUpgradeable {
  using AddressUpgradeable for address;

  event ChangeTokenEvent(address oldAddress, address newAddress);
  event UserPayEvent(string sessionId);
  event MerchantSendEvent(string sessionId);
  event MerchantBatchSendEvent(string sessionId);

  address private vndtToken;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address _vndtToken, address _owner) public initializer {
    __Ownable_init();

    vndtToken = _vndtToken;
    _transferOwnership(_owner);
  }

  function userPay(
    uint256 amount,
    address merchantAddress,
    string calldata sessionId
  ) public returns (bool) {
    emit UserPayEvent(sessionId);
    return ERC20Upgradeable(vndtToken).transferFrom(msg.sender, merchantAddress, amount);
  }

  function userPayWithPermit(
    uint256 amount,
    address merchantAddress,
    string calldata sessionId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public returns (bool) {
    // Use permit
    IERC20PermitUpgradeable(vndtToken).permit(
      msg.sender,
      address(this),
      amount,
      deadline,
      v,
      r,
      s
    );

    // Process pay
    return userPay(amount, merchantAddress, sessionId);
  }

  function merchantSend(
    uint256 amount,
    address recipient,
    string calldata sessionId
  ) public returns (bool) {
    emit MerchantSendEvent(sessionId);
    return ERC20Upgradeable(vndtToken).transferFrom(msg.sender, recipient, amount);
  }

  function merchantSendWithPermit(
    uint256 amount,
    address recipient,
    string calldata sessionId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public returns (bool) {
    // Use permit
    IERC20PermitUpgradeable(vndtToken).permit(
      msg.sender,
      address(this),
      amount,
      deadline,
      v,
      r,
      s
    );

    // Process send
    return merchantSend(amount, recipient, sessionId);
  }

  function merchantBatchSend(
    uint256[] calldata amounts,
    address[] calldata recipients,
    string calldata sessionId
  ) public {
    emit MerchantBatchSendEvent(sessionId);

    uint256 total = 0;
    ERC20Upgradeable token = ERC20Upgradeable(vndtToken);

    for (uint16 i = 0; i < recipients.length; ) {
    unchecked {
      total += amounts[i];
      i += 1;
    }
    }

    require(token.transferFrom(msg.sender, address(this), total));

    for (uint16 i = 0; i < recipients.length; ) {
      require(token.transfer(recipients[i], amounts[i]));
    unchecked {
      i += 1;
    }
    }
  }

  function setVndtToken(address newAddress) public onlyOwner {
    emit ChangeTokenEvent(vndtToken, newAddress);
    vndtToken = newAddress;
  }

  function getVndtToken() public view returns (address) {
    return vndtToken;
  }
}