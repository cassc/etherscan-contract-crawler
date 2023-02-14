// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ILiquidityRestrictor.sol";

contract LETITToken is ERC20BurnableUpgradeable, ERC20CappedUpgradeable, OwnableUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    bool public isLiquidityRestrictorEnabled;

    address public liquidityRestrictor;

    /**
     * @dev External initializer function, cause token is upgradable (see openzeppelin\proxy).
     */
    function initialize() public initializer {
        uint256 maxSupply = 100000000 ether;
        __ERC20_init("Letit Token", "LETIT");
        __ERC20Capped_init(maxSupply);
        __Ownable_init();
        _mint(address(this), maxSupply);
        isLiquidityRestrictorEnabled = true;
    }

    function setLiquidityRestrictor(address liquidityRestrictor_) external onlyOwner {
        liquidityRestrictor = liquidityRestrictor_;
    }

    function setIsLiquidityRestrictorEnabled(bool enabled) external onlyOwner {
        isLiquidityRestrictorEnabled = enabled;
    }

    /**
     * @dev Withdraws `amount` of given `erc20` tokens from the contracts's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function withdraw(address erc20, address to, uint256 amount) external onlyOwner returns (bool) {
        IERC20Upgradeable erc20Impl = IERC20Upgradeable(erc20);
        erc20Impl.safeTransfer(to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`. 
     *
     * Commission will be deducted from given sum if caller is not owner, bridge, router or registered crowdsale:
     * - 0.1% moves to the referrer or DAO pool (if set)
     * - 0.1% will be burned
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits few {Transfer} event.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();
        _transfer(sender, to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance. Please see transfer comments.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");

        if (isLiquidityRestrictorEnabled && liquidityRestrictor != address(0)) {
            (bool allow, string memory message) = ILiquidityRestrictor(liquidityRestrictor).assureLiquidityRestrictions(from, to);
            require(allow, message);
        }

        super._transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        ERC20CappedUpgradeable._mint(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}