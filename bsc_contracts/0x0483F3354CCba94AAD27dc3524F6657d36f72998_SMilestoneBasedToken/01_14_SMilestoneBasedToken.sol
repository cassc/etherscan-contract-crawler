// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Constants.sol";
import "./interfaces/IContractsRegistry.sol";
import "./strategies/interfaces/IStrategy.sol";

contract SMilestoneBasedToken is ERC20Burnable, AccessControl {
  /// @notice Stores the swapper role key hash.
  /// @return Bytes representing swapper role key hash.
  bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");

  /// @notice Stores the address of ContractsRegistry contract.
  /// It is used to get addresses of main contracts as Strategy
  /// @return address of ContractsRegistry contract.
  IContractsRegistry public registry;

  ///@dev Throws if admin or swapper tries to set address of ContractRegistry to ZERO_ADDRESS
  error ZeroAddress();

  ///@dev Throws when sender hasn't role DEFAULT_ADMIN_ROLE or SWAPPER_ROLE
  error NotAdminOrSwapper();

  /// @notice Emits when the administrator updates address of ContractRegistry contract.
  /// @param newRegistry new address of ContractRegistry contract.
  event UpdatedRegistry(address indexed newRegistry);

  constructor(address registry_) ERC20("sMilestoneBased Token", "sMILE") {
    if (registry_ == address(0)) {
      revert ZeroAddress();
    }
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    registry = IContractsRegistry(registry_);
  }

  /// @notice Sets new address of Registry contract.
  /// @dev Only Administrator can call this function.
  /// @param newRegistry new address of Registry contract.
  function setRegistry(address newRegistry)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (newRegistry == address(0)) {
      revert ZeroAddress();
    }
    registry = IContractsRegistry(newRegistry);
    emit UpdatedRegistry(newRegistry);
  }

  /// @notice Create tokens and send it to account address.
  /// @dev Function mint can be called only by addresses with role "Admin" and "Swapper".
  /// @param account address of valid user.
  /// @param amount amount of tokens to create.
  function mint(address account, uint256 amount) external {
    if (
      !(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
        hasRole(SWAPPER_ROLE, _msgSender()))
    ) {
      revert NotAdminOrSwapper();
    }
    _mint(account, amount);
  }

  /// @dev Hook that is called before any transfer of tokens.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount // solhint-disable-line
  ) internal virtual override {
    // will not work during minting or burning
    if (from != address(0) && to != address(0)) {
      IStrategy(registry.getContractByKey(SMILE_STRATEGY_CONTRACT_CODE))
        .validateTransaction(from, to, amount);
    }
  }
}