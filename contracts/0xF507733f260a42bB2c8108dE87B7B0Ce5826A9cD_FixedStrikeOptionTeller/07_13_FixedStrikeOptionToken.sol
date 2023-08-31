// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {OptionToken, ERC20} from "src/bases/OptionToken.sol";

/// @title Fixed Strike Option Token
/// @notice Fixed Strike Option Token Contract (ERC-20 compatible)
///
/// @dev The Fixed Strike Option Token contract is issued by a
///      Fixed Strike Option Token Teller to represent traditional
///      American-style options on the underlying token with a fixed strike price.
///
///      Call option tokens can be exercised for the underlying token 1:1
///      by paying the amount * strike price in the quote token
///      at any time between the eligible and expiry timestamps.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Bond Protocol
contract FixedStrikeOptionToken is OptionToken {
    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The strike price of the option
    /// @return _strike The option strike price specified in the amount of quote tokens per underlying token
    function strike() public pure returns (uint256 _strike) {
        return _getArgUint256(0x9e);
    }

    /* ========== VIEW ========== */

    /// @notice Get collection of option parameters in a single call
    /// @return decimals_  The number of decimals for the option token (same as payout token)
    /// @return payout_    The address of the payout token
    /// @return quote_     The address of the quote token
    /// @return eligible_  The option exercise eligibility timestamp
    /// @return expiry_    The option exercise expiry timestamp
    /// @return receiver_  The address of the receiver
    /// @return call_      Whether the option is a call (true) or a put (false)
    /// @return strike_    The option strike price specified in the amount of quote tokens per underlying token
    function getOptionParameters()
        external
        pure
        returns (
            uint8 decimals_,
            ERC20 payout_,
            ERC20 quote_,
            uint48 eligible_,
            uint48 expiry_,
            address receiver_,
            bool call_,
            uint256 strike_
        )
    {
        return (decimals(), payout(), quote(), eligible(), expiry(), receiver(), call(), strike());
    }
}