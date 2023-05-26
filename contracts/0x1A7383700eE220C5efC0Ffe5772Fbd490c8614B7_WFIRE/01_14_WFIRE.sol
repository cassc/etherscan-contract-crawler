// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

// solhint-disable-next-line max-line-length
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

/**
 * @title WFIRE (Wrapped FIRE).
 *
 * @dev A fixed-balance ERC-20 wrapper for the FIRE rebasing token.
 *
 *      Users deposit FIRE into this contract and are minted wFIRE.
 *
 *      Each account's wFIRE balance represents the fixed percentage ownership
 *      of FIRE's market cap.
 *
 *      For example: 100K wFIRE => 1% of the FIRE market cap
 *        when the FIRE supply is 100M, 100K wFIRE will be redeemable for 1M FIRE
 *        when the FIRE supply is 500M, 100K wFIRE will be redeemable for 5M FIRE
 *        and so on.
 *
 *      We call wFIRE the "wrapper" token and FIRE the "underlying" or "wrapped" token.
 */
contract WFIRE is ERC20Upgradeable, ERC20PermitUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //--------------------------------------------------------------------------
    // Constants

    /// @dev The maximum wFIRE supply.
    uint256 public constant MAX_WFIRE_SUPPLY = 10000000 * (10 ** 18); // 10 M

    //--------------------------------------------------------------------------
    // Attributes

    /// @dev The reference to the FIRE token.
    address private immutable _fire;

    //--------------------------------------------------------------------------

    /// @notice Contract constructor.
    /// @param fire The FIRE ERC20 token address.
    constructor(address fire) {
        _fire = fire;
    }

    /// @notice Contract state initialization.
    /// @param name_ The wFIRE ERC20 name.
    /// @param symbol_ The wFIRE ERC20 symbol.
    function init(string memory name_, string memory symbol_) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
    }

    //--------------------------------------------------------------------------
    // WFIRE write methods

    /// @notice Transfers FIREs from {msg.sender} and mints wFIREs.
    ///
    /// @param wfires The amount of wFIREs to mint.
    /// @return The amount of FIREs deposited.
    function mint(uint256 wfires) external returns (uint256) {
        uint256 fires = _wfireToFire(wfires, _queryFIRESupply());
        _deposit(_msgSender(), _msgSender(), fires, wfires);
        return fires;
    }

    /// @notice Transfers FIREs from {msg.sender} and mints wFIREs,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @param wfires The amount of wFIREs to mint.
    /// @return The amount of FIREs deposited.
    function mintFor(address to, uint256 wfires) external returns (uint256) {
        uint256 fires = _wfireToFire(wfires, _queryFIRESupply());
        _deposit(_msgSender(), to, fires, wfires);
        return fires;
    }

    /// @notice Burns wFIREs from {msg.sender} and transfers FIREs back.
    ///
    /// @param wfires The amount of wFIREs to burn.
    /// @return The amount of FIREs withdrawn.
    function burn(uint256 wfires) external returns (uint256) {
        uint256 fires = _wfireToFire(wfires, _queryFIRESupply());
        _withdraw(_msgSender(), _msgSender(), fires, wfires);
        return fires;
    }

    /// @notice Burns wFIREs from {msg.sender} and transfers FIREs back,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @param wfires The amount of wFIREs to burn.
    /// @return The amount of FIREs withdrawn.
    function burnTo(address to, uint256 wfires) external returns (uint256) {
        uint256 fires = _wfireToFire(wfires, _queryFIRESupply());
        _withdraw(_msgSender(), to, fires, wfires);
        return fires;
    }

    /// @notice Burns all wFIREs from {msg.sender} and transfers FIREs back.
    ///
    /// @return The amount of FIREs withdrawn.
    function burnAll() external returns (uint256) {
        uint256 wfires = balanceOf(_msgSender());
        uint256 fires = _wfireToFire(wfires, _queryFIRESupply());
        _withdraw(_msgSender(), _msgSender(), fires, wfires);
        return fires;
    }

    /// @notice Burns all wFIREs from {msg.sender} and transfers FIREs back,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @return The amount of FIREs withdrawn.
    function burnAllTo(address to) external returns (uint256) {
        uint256 wfires = balanceOf(_msgSender());
        uint256 fires = _wfireToFire(wfires, _queryFIRESupply());
        _withdraw(_msgSender(), to, fires, wfires);
        return fires;
    }

    /// @notice Transfers FIREs from {msg.sender} and mints wFIREs.
    ///
    /// @param fires The amount of FIREs to deposit.
    /// @return The amount of wFIREs minted.
    function deposit(uint256 fires) external returns (uint256) {
        uint256 wfires = _fireToWfire(fires, _queryFIRESupply());
        _deposit(_msgSender(), _msgSender(), fires, wfires);
        return wfires;
    }

    /// @notice Transfers FIREs from {msg.sender} and mints wFIREs,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @param fires The amount of FIREs to deposit.
    /// @return The amount of wFIREs minted.
    function depositFor(address to, uint256 fires) external returns (uint256) {
        uint256 wfires = _fireToWfire(fires, _queryFIRESupply());
        _deposit(_msgSender(), to, fires, wfires);
        return wfires;
    }

    /// @notice Burns wFIREs from {msg.sender} and transfers FIREs back.
    ///
    /// @param fires The amount of FIREs to withdraw.
    /// @return The amount of burnt wFIREs.
    function withdraw(uint256 fires) external returns (uint256) {
        uint256 wfires = _fireToWfire(fires, _queryFIRESupply());
        _withdraw(_msgSender(), _msgSender(), fires, wfires);
        return wfires;
    }

    /// @notice Burns wFIREs from {msg.sender} and transfers FIREs back,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @param fires The amount of FIREs to withdraw.
    /// @return The amount of burnt wFIREs.
    function withdrawTo(address to, uint256 fires) external returns (uint256) {
        uint256 wfires = _fireToWfire(fires, _queryFIRESupply());
        _withdraw(_msgSender(), to, fires, wfires);
        return wfires;
    }

    /// @notice Burns all wFIREs from {msg.sender} and transfers FIREs back.
    ///
    /// @return The amount of burnt wFIREs.
    function withdrawAll() external returns (uint256) {
        uint256 wfires = balanceOf(_msgSender());
        uint256 fires = _wfireToFire(wfires, _queryFIRESupply());
        _withdraw(_msgSender(), _msgSender(), fires, wfires);
        return wfires;
    }

    /// @notice Burns all wFIREs from {msg.sender} and transfers FIREs back,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @return The amount of burnt wFIREs.
    function withdrawAllTo(address to) external returns (uint256) {
        uint256 wfires = balanceOf(_msgSender());
        uint256 fires = _wfireToFire(wfires, _queryFIRESupply());
        _withdraw(_msgSender(), to, fires, wfires);
        return wfires;
    }

    //--------------------------------------------------------------------------
    // WFIRE view methods

    /// @return The address of the underlying "wrapped" token ie) FIRE.
    function underlying() external view returns (address) {
        return _fire;
    }

    /// @return The total FIREs held by this contract.
    function totalUnderlying() external view returns (uint256) {
        return _wfireToFire(totalSupply(), _queryFIRESupply());
    }

    /// @param owner The account address.
    /// @return The FIRE balance redeemable by the owner.
    function balanceOfUnderlying(address owner) external view returns (uint256) {
        return _wfireToFire(balanceOf(owner), _queryFIRESupply());
    }

    /// @param fires The amount of FIRE tokens.
    /// @return The amount of wFIRE tokens exchangeable.
    function underlyingToWrapper(uint256 fires) external view returns (uint256) {
        return _fireToWfire(fires, _queryFIRESupply());
    }

    /// @param wfires The amount of wFIRE tokens.
    /// @return The amount of FIRE tokens exchangeable.
    function wrapperToUnderlying(uint256 wfires) external view returns (uint256) {
        return _wfireToFire(wfires, _queryFIRESupply());
    }

    //--------------------------------------------------------------------------
    // Private methods

    /// @dev Internal helper function to handle deposit state change.
    /// @param from The initiator wallet.
    /// @param to The beneficiary wallet.
    /// @param fires The amount of FIREs to deposit.
    /// @param wfires The amount of wFIREs to mint.
    function _deposit(address from, address to, uint256 fires, uint256 wfires) private {
        IERC20Upgradeable(_fire).safeTransferFrom(from, address(this), fires);

        _mint(to, wfires);
    }

    /// @dev Internal helper function to handle withdraw state change.
    /// @param from The initiator wallet.
    /// @param to The beneficiary wallet.
    /// @param fires The amount of FIREs to withdraw.
    /// @param wfires The amount of wFIREs to burn.
    function _withdraw(address from, address to, uint256 fires, uint256 wfires) private {
        _burn(from, wfires);

        IERC20Upgradeable(_fire).safeTransfer(to, fires);
    }

    /// @dev Queries the current total supply of FIRE.
    /// @return The current FIRE supply.
    function _queryFIRESupply() private view returns (uint256) {
        return IERC20Upgradeable(_fire).totalSupply();
    }

    //--------------------------------------------------------------------------
    // Pure methods

    /// @dev Converts FIREs to wFIRE amount.
    function _fireToWfire(uint256 fires, uint256 totalFIRESupply) private pure returns (uint256) {
        return (fires * MAX_WFIRE_SUPPLY) / totalFIRESupply;
    }

    /// @dev Converts wFIREs amount to FIREs.
    function _wfireToFire(uint256 wfires, uint256 totalFIRESupply) private pure returns (uint256) {
        return (wfires * totalFIRESupply) / MAX_WFIRE_SUPPLY;
    }
}