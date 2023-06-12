// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

contract CoinsenderNfts is
  UUPSUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeMathUpgradeable for uint256;

  string public constant name = "CoinsenderNfts";
  string public constant version = "1";

  address public bank;
  uint256 public minFee;

  /**
  * @notice Emitted when ERC721 tokens are sent to multiple recipients.
  * @param sender - Address of the sender
  * @param token - Address of the ERC721 token contract
  * @param tokenIds - List of ERC721 token IDs that were sent
  * @param recipients - List of recipient addresses
  * @param fee - The fee paid for the transaction
  */
  event ERC721TokensSent(
    address indexed sender,
    address indexed token,
    uint256[] tokenIds,
    address[] recipients,
    uint256 fee
  );

  /**
  * @notice Emitted when ERC1155 tokens are sent to multiple recipients.
  * @param sender - Address of the sender
  * @param token - Address of the ERC1155 token contract
  * @param tokenIds - List of ERC1155 token IDs that were sent
  * @param amounts - List of ERC1155 token amounts that were sent
  * @param recipients - List of recipient addresses
  * @param fee - The fee paid for the transaction
  */
  event ERC1155TokensSent(
    address indexed sender,
    address indexed token,
    uint256[] tokenIds,
    uint256[] amounts,
    address[] recipients,
    uint256 fee
  );

  /**
   * @dev Emitted when a batch of ERC1155 tokens is sent to multiple recipients.
   * @param sender The address that initiated the sending of the tokens.
   * @param token The address of the ERC1155 token contract.
   * @param tokenIds The list of ERC1155 token IDs that were sent.
   * @param amounts The list of ERC1155 token amounts that were sent.
   * @param recipients The list of recipient addresses that received the tokens.
   * @param fee - The fee paid for the transaction
   */
  event ERC1155TokensBatchSent(
    address indexed sender,
    address indexed token,
    uint256[][] tokenIds,
    uint256[][] amounts,
    address[] recipients,
    uint256 fee
  );

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function initialize(address _owner, uint256 _minFee) public initializer {
    require(_owner != address(0), 'Owner address is not set');

    __Ownable_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();

    transferOwnership(_owner);

    bank = _owner;
    minFee = _minFee;
  }

  /**
   * @dev Modifier to check that an array is not empty.
   * @param array The array to check.
   */
  modifier nonEmpty(address[] memory array) {
    require(array.length > 0, 'Array cannot be empty');
    _;
  }

  /**
   * @notice Changes the minFee amount for sending tokens.
   * @param _minFee - new minFee amount
   */
  function changeMinFee(uint256 _minFee) public onlyOwner {
    minFee = _minFee;
  }

  /**
   * @notice Changes the address of the bank where the fees are sent to.
   * @param _bank - new bank address
   */
  function changeBankAddress(address _bank) public onlyOwner {
    require(_bank != address(0), 'Bank not zero');
    bank = _bank;
  }

  /**
  @notice Returns any excess ether sent to the contract back to the sender.
  @dev If the amount sent is greater than the total fee, the difference is returned to the sender.
  @param totalAmount - the total fee amount paid by the sender
  */
  function returnExcessEth(uint256 totalAmount) internal {
    uint256 excess = msg.value.sub(totalAmount);
    if (excess > 0) {
      payable(msg.sender).transfer(excess);
    }
  }

  /**
  * * * @notice This function sends ERC721 tokens to multiple recipients.
  * * * @param recipients - List of recipient addresses
  * * * @param tokenIds - List of ERC721 token IDs to be sent
  * * * @param token - ERC721 token contract address
  */
  function sendERC721(
    address[] memory recipients,
    uint256[] memory tokenIds,
    address token,
    uint256 fee
  ) external payable nonReentrant nonEmpty(recipients) {
    uint256 recipientsLength = recipients.length;
    require(recipientsLength == tokenIds.length, 'Arrays length mismatch');
    require(msg.value >= minFee && fee >= minFee, 'Insufficient fee amount');

    for (uint256 i = 0; i < recipientsLength; i++) {
      require(recipients[i] != address(0), 'Invalid recipient address');

      require(
        IERC721Upgradeable(token).ownerOf(tokenIds[i]) == msg.sender &&
          (IERC721Upgradeable(token).isApprovedForAll(msg.sender, address(this)) ||
            IERC721Upgradeable(token).getApproved(tokenIds[i]) == address(this)),
        'Not authorized to transfer the NFTs'
      );

      IERC721Upgradeable(token).safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
    }

    payable(bank).transfer(fee);

    emit ERC721TokensSent(msg.sender, token, tokenIds, recipients, fee);

    returnExcessEth(fee);
  }

  /**
  * * @notice This function sends ERC1155 tokens to multiple recipients.
  * * @param recipients - List of recipient addresses
  * * @param amounts - List of ERC1155 token amounts to be sent
  * * @param tokenIds - List of ERC1155 token IDs to be sent
  * * @param token - ERC1155 token contract address
  */
  function sendERC1155(
    address[] memory recipients,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    address token,
    uint256 fee
  ) external payable nonReentrant nonEmpty(recipients) {
    uint256 recipientsLength = recipients.length;
    require(
      recipientsLength == amounts.length && recipientsLength == tokenIds.length,
      'Input arrays must have the same length'
    );
    require(msg.value >= minFee && fee >= minFee, 'Insufficient fee amount');

    for (uint256 i = 0; i < recipientsLength; i++) {
      require(recipients[i] != address(0), 'Recipient address cannot be zero');
      require(
        IERC1155Upgradeable(token).isApprovedForAll(msg.sender, address(this)) ||
          IERC1155Upgradeable(token).balanceOf(msg.sender, tokenIds[i]) >= amounts[i],
        'Not authorized to transfer the NFTs'
      );
      IERC1155Upgradeable(token).safeTransferFrom(
        msg.sender,
        recipients[i],
        tokenIds[i],
        amounts[i],
        ''
      );
    }

    payable(bank).transfer(fee);

    emit ERC1155TokensSent(msg.sender, token, tokenIds, amounts, recipients, fee);

    returnExcessEth(fee);
  }

  /**
  * @notice This function sends batches of ERC1155 tokens to multiple recipients.
  * @param recipients - List of recipient addresses
  * @param amounts - List of lists of ERC1155 token amounts to be sent
  * @param tokenIds - List of lists of ERC1155 token IDs to be sent
  * @param token - ERC1155 token contract address
  */
  function sendBatchERC1155(
    address[] memory recipients,
    uint256[][] memory tokenIds,
    uint256[][] memory amounts,
    address token,
    uint256 fee
  ) external payable nonReentrant nonEmpty(recipients) {
    uint256 recipientsLength = recipients.length;
    require(
      recipientsLength == amounts.length && recipientsLength == tokenIds.length,
      'Input arrays must have the same length'
    );
    require(msg.value >= minFee && fee >= minFee, 'Insufficient fee amount');

    for (uint256 i = 0; i < recipientsLength; i++) {
      uint256[] memory batchTokenIds = tokenIds[i];
      uint256[] memory batchAmounts = amounts[i];
      uint256 batchTokenIdsLength = batchTokenIds.length;
      require(batchTokenIdsLength > 0, 'Empty batch');
      for (uint256 j = 0; j < batchTokenIdsLength; j++) {
        require(
          IERC1155Upgradeable(token).isApprovedForAll(msg.sender, address(this)) ||
            IERC1155Upgradeable(token).balanceOf(msg.sender, batchTokenIds[j]) >= batchAmounts[j],
          'Not authorized to transfer the NFTs'
        );
      }
      IERC1155Upgradeable(token).safeBatchTransferFrom(
        msg.sender,
        recipients[i],
        batchTokenIds,
        batchAmounts,
        ''
      );
    }

    payable(bank).transfer(fee);

    emit ERC1155TokensBatchSent(msg.sender, token, tokenIds, amounts, recipients, fee);

    returnExcessEth(fee);
  }
}