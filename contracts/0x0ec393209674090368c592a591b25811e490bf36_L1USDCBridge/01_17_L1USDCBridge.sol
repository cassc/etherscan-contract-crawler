// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { IUSDC } from "./interfaces/IUSDC.sol";
import { USDCBridge } from "./abstracts/USDCBridge.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title L1USDCBridge
 * @dev L1 USDC Bridge to ConsenSys's L2 Linea
 */
contract L1USDCBridge is USDCBridge, ReentrancyGuardUpgradeable {
  using SafeERC20 for IUSDC;

  /**
   * @dev Sends the sender's USDC from L1 to L2, locks the USDC sent
   * in this contract and sends a message to the message bridge
   * contract to mint the equivalent USDC on L2
   * @param amount The amount of USDC to send
   */
  function deposit(
    uint256 amount
  )
    external
    payable
    whenNotPaused
    remoteUSDCBridgeInitialized
    nonZeroAmount(amount)
    enoughSenderBalance(amount)
  {
    _deposit(amount, msg.sender);
  }

  /**
   * @dev Sends the sender's USDC from L1 to the recipient on L2, locks the USDC sent
   * in this contract and sends a message to the message bridge
   * contract to mint the equivalent USDC on L2
   * @param amount The amount of USDC to send
   * @param to The recipient's address to receive the funds
   */
  function depositTo(
    uint256 amount,
    address to
  )
    external
    payable
    whenNotPaused
    remoteUSDCBridgeInitialized
    nonZeroAmount(amount)
    nonZeroAddress(to)
    enoughSenderBalance(amount)
  {
    _deposit(amount, to);
  }

  function _deposit(uint256 amount, address to) internal nonReentrant {
    // amountAfterTransfer can different from amount if fees are added when transferring USDC
    uint256 amountAfterTransfer = _transferUSDCToUSDCBridge(amount);

    // Increase locked balance on L1
    balance = balance + amountAfterTransfer;
    _sendMessage(amountAfterTransfer, to);
    emit Deposited(msg.sender, amountAfterTransfer, to);
  }

  /**
   * @dev This function is called by the message bridge when transferring USDC from L2 to L1
   * It burns the USDC on L2 and unlocks the equivalent USDC from this contract to the recipient
   * @param recipient The recipient to receive the USDC on L1
   * @param amount The amount of USDC to receive
   */
  function receiveFromOtherLayer(
    address recipient,
    uint256 amount
  ) external override onlyMessageService senderIsRemoteUSDCBridge {
    usdc.safeTransfer(recipient, amount);

    // Decrease locked balance on L1
    balance = balance - amount;
    emit ReceivedFromOtherLayer(recipient, amount);
  }
}