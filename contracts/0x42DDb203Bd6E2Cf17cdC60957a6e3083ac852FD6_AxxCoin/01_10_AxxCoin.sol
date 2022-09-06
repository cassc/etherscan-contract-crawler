//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Stable coin smart contract implementation for Axx Coin
/// @notice ERC20 smartcontract for Axx stable coin
contract AxxCoin is ERC20, AccessControl {
  // keccak hash for role will be used for role validations
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  bytes32 public constant DEPOSIT_WALLET_ROLE =
    keccak256("DEPOSIT_WALLET_ROLE");

  constructor(string memory _token, string memory _symbol)
    ERC20(_token, _symbol)
  {
    // Deployer will be default admin role
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /// @notice Mints tokens against recipient
  /// @param recipient Wallet address of recipient
  /// @param amount Amount to mint
  function mint(address recipient, uint256 amount) public {
    // Check if caller has minter role
    require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");

    require(
      hasRole(DEPOSIT_WALLET_ROLE, recipient),
      "Recipient is not deposit wallet"
    );

    // Mint tokens
    _mint(recipient, amount);
  }

  /// @notice Burns tokens from caller wallet
  /// @param amount Amount to burn
  function burn(uint256 amount) public {
    // Check if caller has burner role
    require(hasRole(BURNER_ROLE, _msgSender()), "Caller is not a burner");

    // Burn tokens
    _burn(_msgSender(), amount);
  }

  /// @notice Changes default decimal 18 to 5
  /// @return decimal value
  function decimals() public view virtual override returns (uint8) {
    return 5;
  }
}