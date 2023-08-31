// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {CloneERC20} from "src/lib/clones/CloneERC20.sol";

/// @title Option Token
/// @notice Option Token Contract (ERC-20 compatible)
///
/// @dev The Option Token contract is issued by a Option Token Teller to
///      represent American-style options on the underlying token.
///
///      Call option tokens can be exercised for the underlying token 1:1
///      by paying the amount * strike price in the quote token
///      at any time between the eligible and expiry timestamps.
///
///      Put option tokens can be exercised for the underlying token 1:1
///      by paying the amount of the underlying token to receive the
///      amount * strike price in the quote token at any time between
///      the eligible and expiry timestamps.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Bond Protocol
abstract contract OptionToken is CloneERC20 {
    /* ========== ERRORS ========== */
    error OptionToken_OnlyTeller();

    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The token that the option is on
    /// @return _payout The address of the payout token
    function payout() public pure returns (ERC20 _payout) {
        return ERC20(_getArgAddress(0x41));
    }

    /// @notice The token that the option is quoted in
    /// @return _quote The address of the quote token
    function quote() public pure returns (ERC20 _quote) {
        return ERC20(_getArgAddress(0x55));
    }

    /// @notice Timestamp at which the Option token can first be exercised
    /// @return _eligible The option exercise eligibility timestamp
    function eligible() public pure returns (uint48 _eligible) {
        return _getArgUint48(0x69);
    }

    /// @notice Timestamp at which the Option token cannot be exercised after
    /// @return _expiry The option exercise expiry timestamp
    function expiry() public pure returns (uint48 _expiry) {
        return _getArgUint48(0x6f);
    }

    /// @notice Address that will receive the proceeds when option tokens are exercised
    /// @return _receiver The address of the receiver
    function receiver() public pure returns (address _receiver) {
        return _getArgAddress(0x75);
    }

    /// @notice Whether the option is a call or a put
    /// @return _call True if the option is a call, false if the option is a put
    function call() public pure returns (bool _call) {
        return _getArgBool(0x89);
    }

    /// @notice Address of the Teller that created the token
    function teller() public pure returns (address _teller) {
        return _getArgAddress(0x8a);
    }

    /* ========== MINT/BURN ========== */

    /// @notice Mint option tokens
    /// @notice Only callable by the Teller that created the token
    /// @param to     The address to mint to
    /// @param amount The amount to mint
    function mint(address to, uint256 amount) external {
        if (msg.sender != teller()) revert OptionToken_OnlyTeller();
        _mint(to, amount);
    }

    /// @notice Burn option tokens
    /// @notice Only callable by the Teller that created the token
    /// @param from   The address to burn from
    /// @param amount The amount to burtn
    function burn(address from, uint256 amount) external {
        if (msg.sender != teller()) revert OptionToken_OnlyTeller();
        _burn(from, amount);
    }
}