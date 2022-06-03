//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@fractal-framework/core-contracts/contracts/ModuleBase.sol";
import "./interfaces/ITreasuryModule.sol";

/// @notice A treasury module contract for managing a DAOs assets
contract TreasuryModule is ERC721Holder, ModuleBase, ITreasuryModule {
  using SafeERC20 for IERC20;
  
  /// @notice Function for initializing the contract that can only be called once
  /// @param _accessControl The address of the access control contract
  function initialize(
        address _accessControl
    ) external initializer {
        __initBase(_accessControl, msg.sender, "Treasury Module");
    }

  /// @notice Allows the contract to receive Ether
  receive() external payable {
    emit EthDeposited(msg.sender, msg.value);
  }

  /// @notice Allows the owner to withdraw ETH to multiple addresses
  /// @param recipients Array of addresses that ETH will be withdrawn to
  /// @param amounts Array of amounts of ETH that will be withdrawnnn
  function withdrawEth(
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external authorized {
    if (recipients.length != amounts.length) {
      revert UnequalArrayLengths();
    }

    uint256 recipientsLength =  recipients.length;
    for (uint256 index = 0; index < recipientsLength;) {
      payable(recipients[index]).transfer(amounts[index]);
      unchecked {
       index ++; 
      }
    }

    emit EthWithdrawn(recipients, amounts);
  }

  /// @notice Allows the owner to deposit ERC-20 tokens from multiple addresses
  /// @param tokenAddresses Array of token contract addresses
  /// @param senders Array of addresses that the ERC-20 token will be transferred from
  /// @param amounts Array of amounts of the ERC-20 token that will be transferred
  function depositERC20Tokens(
    address[] calldata tokenAddresses,
    address[] calldata senders,
    uint256[] calldata amounts
  ) external authorized {
    if (
      tokenAddresses.length != senders.length ||
      tokenAddresses.length != amounts.length
    ) {
      revert UnequalArrayLengths();
    }

    uint256 tokenAddressesLength = tokenAddresses.length;
    for (uint256 index = 0; index < tokenAddressesLength;) {
      IERC20(tokenAddresses[index]).safeTransferFrom(
        senders[index],
        address(this),
        amounts[index]
      );
      unchecked {
        index ++;
      }
    }

    emit ERC20TokensDeposited(tokenAddresses, senders, amounts);
  }

  /// @notice Allows the owner to withdraw ERC-20 tokens from multiple addresses
  /// @param tokenAddresses Array of token contract addresses
  /// @param recipients Array of addresses that the ERC-20 token will be transferred to
  /// @param amounts Array of amounts of the ERC-20 token that will be transferred 
  function withdrawERC20Tokens(
    address[] calldata tokenAddresses,
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external authorized {
    if (
      tokenAddresses.length != recipients.length ||
      tokenAddresses.length != amounts.length
    ) {
      revert UnequalArrayLengths();
    }

    uint256 tokenAddressesLength =  tokenAddresses.length;
    for (uint256 index = 0; index < tokenAddressesLength; index ++) {
      IERC20(tokenAddresses[index]).safeTransfer(
        recipients[index],
        amounts[index]
      );
      unchecked {
        index ++;
      }
    }

    emit ERC20TokensWithdrawn(tokenAddresses, recipients, amounts);
  }

  /// @notice Allows the owner to deposit ERC-721 tokens from multiple addresses
  /// @param tokenAddresses Array of token contract addresses
  /// @param senders Array of addresses that the ERC-721 tokens will be transferred from
  /// @param tokenIds Array of amounts of the ERC-20 token that will be transferred 
  function depositERC721Tokens(
    address[] calldata tokenAddresses,
    address[] calldata senders,
    uint256[] calldata tokenIds
  ) external authorized {
    if (
      tokenAddresses.length != senders.length ||
      tokenAddresses.length != tokenIds.length
    ) {
      revert UnequalArrayLengths();
    }

    uint256 tokenAddressesLength = tokenAddresses.length;
    for (uint256 index = 0; index < tokenAddressesLength;) {
      IERC721(tokenAddresses[index]).safeTransferFrom(
        senders[index],
        address(this),
        tokenIds[index]
      );
      unchecked {
        index ++;
      }
    }

    emit ERC721TokensDeposited(tokenAddresses, senders, tokenIds);
  }

  /// @notice Allows the owner to withdraw ERC-721 tokens from multiple addresses
  /// @param tokenAddresses Array of token contract addresses
  /// @param recipients Array of addresses that the ERC-721 tokens will be transferred to
  /// @param tokenIds Array of amounts of the ERC-20 token that will be transferred 
  function withdrawERC721Tokens(
    address[] calldata tokenAddresses,
    address[] calldata recipients,
    uint256[] calldata tokenIds
  ) external authorized {
    if (
      tokenAddresses.length != recipients.length ||
      tokenAddresses.length != tokenIds.length
    ) {
      revert UnequalArrayLengths();
    }

    uint256 tokenAddressesLength = tokenAddresses.length;  
    for (uint256 index = 0; index < tokenAddressesLength;) {
      IERC721(tokenAddresses[index]).safeTransferFrom(
        address(this),
        recipients[index],
        tokenIds[index]
      );
      unchecked {
        index ++;
      }
    }

    emit ERC721TokensWithdrawn(tokenAddresses, recipients, tokenIds);
  }

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(ITreasuryModule).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}