// contracts/EYESToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EYESToken is AccessControl, ERC20, ERC20Burnable, ERC20Pausable {
    bytes32 public constant ROLE_ADMIN       = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_ADMIN_ADMIN = keccak256("ROLE_ADMIN_ADMIN");
    bytes32 public constant ROLE_PREVENT     = keccak256("ROLE_PREVENT");

    mapping (address => bool) private _locked_wallets;

    event WalletStateChanged(address indexed _wallet, bool _locked);

    constructor(address admin, address eco, address team, address[15] memory sales, address[20] memory markets) ERC20("EYES Protocol", "EYES") {
        /* Setup roles
         * - Admin address has role `ROLE_ADMIN`
         * - Admin address has role `ROLE_ADMIN_ADMIN`
         * Addresses with `ROLE_ADMIN` can
         * - Pause/unpause token contract
         * - Lock/unlock wallet
         * Addresses with `ROLE_ADMIN_ADMIN` can
         * - Grant other addresses `ROLE_ADMIN` role */
        _setupRole(ROLE_ADMIN,       admin);
        _setupRole(ROLE_ADMIN_ADMIN, admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN_ADMIN);

        /* By default `ROLE_ADMIN_ADMIN` and `ROLE_ADMIN_ADMIN`'s admin role
         * are the same. Setting it to `ROLE_PREVENT` to prevent someone with
         * `ROLE_ADMIN_ADMIN` role from granting others `ROLE_ADMIN_ADMIN` role. */
        _setRoleAdmin(ROLE_ADMIN_ADMIN, ROLE_PREVENT);

        uint256 EXPECTED_TOTAL_SUPPLY = 10000000000 ether;
        uint256 MINTAGE_ECO_TOKEN     =  5000000000 ether;
        uint256 MINTAGE_TEAM_TOKEN    =  1500000000 ether;
        uint256 MINTAGE_PER_WALLET    =   100000000 ether;

        _mint(eco, MINTAGE_ECO_TOKEN);
        _approve(eco, admin, MINTAGE_ECO_TOKEN);

        _mint(team, MINTAGE_TEAM_TOKEN);
        _approve(team, admin, MINTAGE_TEAM_TOKEN);

        for (uint i = 0; i < sales.length; i += 1) {
            _mint(sales[i], MINTAGE_PER_WALLET);
            _approve(sales[i], admin, MINTAGE_PER_WALLET);
        }
        for (uint i = 0; i < markets.length; i += 1) {
            _mint(markets[i], MINTAGE_PER_WALLET);
            _approve(markets[i], admin, MINTAGE_PER_WALLET);
        }
        assert (totalSupply() == EXPECTED_TOTAL_SUPPLY);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        require (!_locked_wallets[from], "source wallet address is locked");
        super._beforeTokenTransfer(from, to, amount);
    }

    function lock_wallet(address wallet, bool lock) external onlyRole(ROLE_ADMIN) {
        require (wallet != address(0x0), "you can't lock 0x0");
        require (_locked_wallets[wallet] != lock, "the wallet is set to given state already");
        _locked_wallets[wallet] = lock;
        emit WalletStateChanged(wallet, lock);
    }

    function pause() external onlyRole(ROLE_ADMIN) whenNotPaused {
        _pause();
    }

    function unpause() external onlyRole(ROLE_ADMIN) whenPaused {
        _unpause();
    }
}