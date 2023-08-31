// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { IUSDC } from "../interfaces/IUSDC.sol";
import { IUSDCBridge } from "../interfaces/IUSDCBridge.sol";
import { IMessageService } from "../interfaces/IMessageService.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract USDCBridge is
  IUSDCBridge,
  PausableUpgradeable,
  Ownable2StepUpgradeable
{
  using SafeERC20 for IUSDC;

  /// @dev Used in the destroy function implemented by the derived contract
  /// https://eips.ethereum.org/EIPS/eip-1967
  bytes32 internal constant _ADMIN_SLOT =
    bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

  address private constant ADDRESS_ZERO = address(0x0);

  address public remoteUSDCBridge;

  IMessageService public messageService;

  IUSDC public usdc;

  uint256 public balance;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    IMessageService _messageService,
    IUSDC _usdc
  ) external initializer {
    __Pausable_init();
    __Ownable2Step_init();
    messageService = _messageService;
    usdc = _usdc;
  }

  modifier onlyMessageService() {
    if (msg.sender != address(messageService))
      revert NotMessageService(msg.sender, address(messageService));
    _;
  }

  modifier nonZeroAmount(uint256 amount) {
    if (amount == 0) revert ZeroAmountNotAllowed(amount);
    _;
  }

  modifier senderIsRemoteUSDCBridge() {
    if (messageService.sender() != remoteUSDCBridge)
      revert NotFromRemoteUSDCBridge(messageService.sender(), remoteUSDCBridge);
    _;
  }

  modifier remoteUSDCBridgeInitialized() {
    if (remoteUSDCBridge == ADDRESS_ZERO) revert RemoteUSDCBridgeNotSet();
    _;
  }

  modifier enoughSenderBalance(uint256 amount) {
    uint256 senderBalance = usdc.balanceOf(msg.sender);
    if (senderBalance < amount)
      revert SenderBalanceTooLow(amount, senderBalance);
    _;
  }

  modifier nonZeroAddress(address addr) {
    if (addr == ADDRESS_ZERO) revert ZeroAddressNotAllowed(addr);
    _;
  }

  /**
   * @dev Sends the message to the message bridge's contract containing the function
   * and contract to call on the other layer to transfer the USDC, also the recipient has to be specified
   * @param amount The amount of USDC to send
   * @param to The recipient's address to receive the funds
   */
  function _sendMessage(uint256 amount, address to) internal {
    messageService.sendMessage{ value: msg.value }(
      remoteUSDCBridge,
      msg.value,
      abi.encodeCall(IUSDCBridge.receiveFromOtherLayer, (to, amount))
    );
  }

  /**
   * @dev Transfer the USDC from the depositor to this contract
   * and returns the amount the contract has actually received after
   * the transfer
   * @param amount Amount of tokens to transfer
   */
  function _transferUSDCToUSDCBridge(
    uint256 amount
  ) internal returns (uint256) {
    uint256 previousBalance = usdc.balanceOf(address(this));
    usdc.safeTransferFrom(msg.sender, address(this), amount);
    amount = usdc.balanceOf(address(this)) - previousBalance;
    return amount;
  }

  /**
   * @dev Owner is able to send back funds to a user that would mistakenly send funds to the contract
   * using the transfer function of USDC contract instead of the deposit function of this bridge.
   * @param to The recipient address
   * @param amount The amount of USDC to be sent back
   */
  function rescueTransfer(
    address to,
    uint256 amount
  ) external onlyOwner nonZeroAddress(to) {
    uint256 extraUSDC = usdc.balanceOf(address(this)) - balance;
    if (amount > extraUSDC) revert AmountTooBig(amount, extraUSDC);

    usdc.safeTransfer(to, amount);
  }

  /**
   * @dev Owner can change the l2 message bridge
   * It will change the current l2 message bridge
   * @param newMessageService The new message bridge address
   */
  function changeMessageService(
    IMessageService newMessageService
  ) external onlyOwner nonZeroAddress(address(newMessageService)) {
    if (messageService == newMessageService)
      revert SameMessageServiceAddr(address(messageService));

    address oldAddress = address(messageService);
    messageService = newMessageService;

    emit MessageServiceUpdated(oldAddress, address(newMessageService));
  }

  function setRemoteUSDCBridge(address _remoteUSDCBridge) external onlyOwner {
    if (remoteUSDCBridge != ADDRESS_ZERO)
      revert RemoteUSDCBridgeAlreadySet(remoteUSDCBridge);
    remoteUSDCBridge = _remoteUSDCBridge;

    emit RemoteUSDCBridgeSet(_remoteUSDCBridge);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev This function is called by the message bridge when transferring USDC from one layer to another layer
   * It will mint or unlock the USDC depending on the implementation overriding this method
   * @param recipient The recipient to receive the USDC on the current layer
   * @param amount The amount of USDC to receive
   */
  function receiveFromOtherLayer(
    address recipient,
    uint256 amount
  ) external virtual {}
}