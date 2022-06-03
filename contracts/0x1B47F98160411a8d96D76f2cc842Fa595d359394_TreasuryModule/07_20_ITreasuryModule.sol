//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITreasuryModule {
  error UnequalArrayLengths();

  event EthDeposited(address sender, uint256 amount);

  event EthWithdrawn(address[] recipients, uint256[] amounts);

  event ERC20TokensDeposited(
    address[] tokenAddresses,
    address[] senders,
    uint256[] amounts
  );

  event ERC20TokensWithdrawn(
    address[] tokenAddresses,
    address[] recipients,
    uint256[] amounts
  );

  event ERC721TokensDeposited(
    address[] tokenAddresses,
    address[] senders,
    uint256[] tokenIds
  );

  event ERC721TokensWithdrawn(
    address[] tokenAddresses,
    address[] recipients,
    uint256[] tokenIds
  );
  
  /// @notice Function for initializing the contract that can only be called once
  /// @param _accessControl The address of the access control contract
  function initialize(
        address _accessControl
    ) external;

  /// @notice Allows the contract to receive Ether
  receive() external payable;

  /// @notice Allows the owner to withdraw ETH to multiple addresses
  /// @param recipients Array of addresses that ETH will be withdrawn to
  /// @param amounts Array of amounts of ETH that will be withdrawnnn
  function withdrawEth(
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external;

  /// @notice Allows the owner to deposit ERC-20 tokens from multiple addresses
  /// @param tokenAddresses Array of token contract addresses
  /// @param senders Array of addresses that the ERC-20 token will be transferred from
  /// @param amounts Array of amounts of the ERC-20 token that will be transferred
  function depositERC20Tokens(
    address[] calldata tokenAddresses,
    address[] calldata senders,
    uint256[] calldata amounts
  ) external;

  /// @notice Allows the owner to withdraw ERC-20 tokens from multiple addresses
  /// @param tokenAddresses Array of token contract addresses
  /// @param recipients Array of addresses that the ERC-20 token will be transferred to
  /// @param amounts Array of amounts of the ERC-20 token that will be transferred 
  function withdrawERC20Tokens(
    address[] calldata tokenAddresses,
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external;

  /// @notice Allows the owner to deposit ERC-721 tokens from multiple addresses
  /// @param tokenAddresses Array of token contract addresses
  /// @param senders Array of addresses that the ERC-721 tokens will be transferred from
  /// @param tokenIds Array of amounts of the ERC-20 token that will be transferred 
  function depositERC721Tokens(
    address[] calldata tokenAddresses,
    address[] calldata senders,
    uint256[] calldata tokenIds
  ) external;

  /// @notice Allows the owner to withdraw ERC-721 tokens from multiple addresses
  /// @param tokenAddresses Array of token contract addresses
  /// @param recipients Array of addresses that the ERC-721 tokens will be transferred to
  /// @param tokenIds Array of amounts of the ERC-20 token that will be transferred 
  function withdrawERC721Tokens(
    address[] calldata tokenAddresses,
    address[] calldata recipients,
    uint256[] calldata tokenIds
  ) external;
}