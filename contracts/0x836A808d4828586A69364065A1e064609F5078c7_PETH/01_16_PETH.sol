// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

 /// @title PETH - JPEG'd ETH Stablecoin
 /// @notice PETH is minted by the {PETHNFTVault} (backed by NFTs) and the {FungibleAssetVaultForDAO} (backed by fungible assets)
 /// @dev Roles (at launch)
 /// DEFAULT_ADMIN_ROLE: DAO
 /// MINTER_ROLE: Vaults ({FungibleAssetVaultForDAO} and {PETHNFTVault})
 /// PAUSER_ROLE: None
contract PETH is
    Context,
    AccessControlEnumerable,
    ERC20Burnable,
    ERC20Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() ERC20("JPEG\xE2\x80\x99d ETH", "pETH") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Creates `amount` tokens and assigns them to `account`, increasing
    /// the total supply.
    ///
    /// Emits a {Transfer} event with `from` set to the zero address.
    ///
    /// Requirements:
    ///
    /// - `account` cannot be the zero address.
    ///
    function mint(address to, uint256 amount) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "PETH: must have minter role to mint"
        );
        _mint(to, amount);
    }

    /// @dev Triggers stopped state.
    ///
    /// Requirements:
    ///
    /// - The contract must not be paused.
    ///
    function pause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "PETH: must have pauser role to pause"
        );
        _pause();
    }

    /// @dev Returns to normal state.
    ///
    /// Requirements:
    ///
    /// - The contract must be paused.
    ///
    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "PETH: must have pauser role to unpause"
        );
        _unpause();
    }

    //override required by solidity
    /// @inheritdoc ERC20Pausable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}