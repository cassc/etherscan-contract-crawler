pragma solidity >=0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOmniAccount {
  struct TokenIdentifier {
    address collection;
    uint256 id;
  }
  
  error TransferFailed();
  error InsufficientBalances();
  error Unauthorized();
  error MismatchedInputLength();

  /// @notice Emitted when an account is created
  /// @param account the account that's been created
  /// @param owner the owner of the account
  event AccountCreated(address account, address owner);

  /// @notice Emitted when an owner deposits ETH into an account
  /// @param account the account where the ETH was deposited
  /// @param owner the owner of the ETH (not the account!)
  /// @param amount amount of ETH deposited
  event ETHDeposited(address account, address owner, uint256 amount);

  /// @notice Emitted when an owner deposits ERC20 tokens into an account
  /// @param account the account where the tokens were deposited
  /// @param owner the owner of the tokens (not the account!)
  /// @param tokens the token deposited
  /// @param amounts amount of tokens deposited
  event ERC20Deposited(address account, address owner, IERC20[] tokens, uint256[] amounts);

  /// @notice Emitted when an owner deposits ERC721 tokens into an account
  /// @param account the account where the tokens were deposited
  /// @param owner the owner of the tokens (not the account!)
  /// @param tokens the token identifiers deposited
  event ERC721Deposited(address account, address owner, TokenIdentifier[] tokens);

  /// @notice Emitted when an owner deposits ERC1155 tokens into an account
  /// @param account the account where the tokens were deposited
  /// @param owner the owner of the tokens (not the account!)
  /// @param tokens the token identifiers deposited
  /// @param amounts amount of tokens deposited
  event ERC1155Deposited(address account, address owner, TokenIdentifier[] tokens, uint256[] amounts);

  /// @notice Emitted when an owner withdraws ETH from an account
  /// @param account the account where the ETH was withdrawn
  /// @param owner the owner of the ETH (not the account!)
  /// @param amount amount of ETH withdrawn
  event ETHWithdrawn(address account, address owner, uint256 amount);

  /// @notice Emitted when an owner withdraws ERC20 tokens from an account
  /// @param account the account where the tokens were withdrawn
  /// @param owner the owner of the tokens (not the account!)
  /// @param tokens the token withdrawn
  /// @param amounts amount of tokens withdrawn
  event ERC20Withdrawn(address account, address owner, IERC20[] tokens, uint256[] amounts);

  /// @notice Emitted when an owner withdraws ERC721 tokens from an account
  /// @param account the account where the tokens were withdrawn
  /// @param owner the owner of the tokens (not the account!)
  /// @param tokens the token identifiers withdrawn
  event ERC721Withdrawn(address account, address owner, TokenIdentifier[] tokens);

  /// @notice Emitted when an owner withdraws ERC1155 tokens from an account
  /// @param account the account where the tokens were withdrawn
  /// @param owner the owner of the tokens (not the account!)
  /// @param tokens the token identifiers withdrawn
  /// @param amounts amount of tokens withdrawn
  event ERC1155Withdrawn(address account, address owner, TokenIdentifier[] tokens, uint256[] amounts);

  /// @notice Deposit ETH
  function depositETH() external payable;

  /// @notice Deposit ERC20 tokens
  /// @param tokens tokens deposited
  /// @param amounts amounts deposited
  function depositERC20(IERC20[] calldata tokens, uint256[] calldata amounts) external;

  /// @notice Deposit ERC721 tokens
  /// @param tokens tokens deposited
  function depositERC721(TokenIdentifier[] calldata tokens) external;

  /// @notice Deposit ERC1155 tokens
  /// @param tokens tokens deposited
  /// @param amounts amounts deposited
  function depositERC1155(TokenIdentifier[] calldata tokens, uint256[]calldata amounts) external;

  /// @notice Withdraw ETH
  /// @param amount amount withdrawn
  function withdrawETH(uint256 amount) external;

  /// @notice Withdraw ERC20 tokens
  /// @param tokens tokens withdrawn
  /// @param amounts amounts withdrawn
  function withdrawERC20(IERC20[] calldata tokens, uint256[] calldata amounts) external;

  /// @notice Withdraw orders
  /// @param tokens tokens withdrawn
  function withdrawERC721(TokenIdentifier[] calldata tokens) external;

  /// @notice Withdraw ERC1155 tokens
  /// @param tokens tokens withdrawn
  /// @param amounts amounts withdrawn
  function withdrawERC1155(TokenIdentifier[] calldata tokens, uint256[] calldata amounts) external;
}