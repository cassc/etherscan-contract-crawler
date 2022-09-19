// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenMintNotPaused`, `whenMintPaused`, `whenRedeemNotPaused` 
 * and `whenRedeemPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract TradePausable {

    bool private _mintPaused;
    bool private _redeemPaused;


    /// @dev Emitted when the mint pause is triggered by `account`.
    event MintPaused(address account);

    /// @dev Emitted when the redeem pause is triggered by `account`.
    event RedeemPaused(address account);

    /// @dev Emitted when the mint pause is lifted by `account`.
    event MintUnpaused(address account);

    /// @dev Emitted when the redeem pause is lifted by `account`.
    event RedeemUnpaused(address account);


    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenMintNotPaused() {
        _requireMintNotPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenMintPaused() {
        _requireMintPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenRedeemNotPaused() {
        _requireRedeemNotPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenRedeemPaused() {
        _requireRedeemPaused();
        _;
    }


    /// @dev Initializes the contract in unpaused state.
    constructor() {
        _mintPaused= false;
        _redeemPaused= false;
    }

    
    function isMintPaused() public view returns(bool) {
        return _mintPaused;
    }

    function isRedeemPaused() public view returns(bool) {
        return _redeemPaused;
    }


    /// @dev Throws if the contract is paused.
    function _requireMintNotPaused() internal view virtual {
        require(!_mintPaused, "Mint paused");
    }

    /// @dev Throws if the contract is not paused.
    function _requireMintPaused() internal view virtual {
        require(_mintPaused); // TradePausable: mint not paused
    }

    /// @dev Throws if the contract is paused.
    function _requireRedeemNotPaused() internal view virtual {
        require(!_redeemPaused); // TradePausable: redeem paused
    }

    /// @dev Throws if the contract is not paused.
    function _requireRedeemPaused() internal view virtual {
        require(_redeemPaused); // TradePausable: redeem not paused
    }

    /// @dev Triggers stopped state for mint
    function _pauseMint() internal virtual {
        _mintPaused = true;
        emit MintPaused(msg.sender);
    }

    /// @dev Returns to normal state.
    function _unpauseMint() internal virtual {
        _mintPaused = false;
        emit MintUnpaused(msg.sender);
    }

    /// @dev Triggers stopped state for redeem 
    function _pauseRedeem() internal virtual {
        _redeemPaused = true;
        emit RedeemPaused(msg.sender);
    }

    /// @dev Returns to normal state.
    function _unpauseRedeem() internal virtual {
        _redeemPaused = false;
        emit RedeemUnpaused(msg.sender);
    }
}