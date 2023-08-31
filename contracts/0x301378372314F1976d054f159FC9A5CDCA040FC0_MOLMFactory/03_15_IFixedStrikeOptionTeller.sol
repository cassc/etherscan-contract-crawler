// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IOptionTeller} from "src/interfaces/IOptionTeller.sol";
import {FixedStrikeOptionToken} from "src/fixed-strike/FixedStrikeOptionToken.sol";

interface IFixedStrikeOptionTeller is IOptionTeller {
    /// @notice             Deploy a new ERC20 fixed strike option token and return its address
    /// @dev                If an option token already exists for the parameters, it returns that address
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return             Address of the ERC20 fixed strike option token being created
    function deploy(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external returns (FixedStrikeOptionToken);

    /// @notice              Deposit an ERC20 token and mint an ERC20 fixed strike option token
    /// @param optionToken_  Fixed strike option token to mint
    /// @param amount_       Amount of option tokens to mint (also the number of payout tokens required to be deposited)
    function create(FixedStrikeOptionToken optionToken_, uint256 amount_) external;

    /// @notice              Exercise an ERC20 fixed strike option token. Provide required quote tokens and receive amount of payout tokens.
    /// @param optionToken_  Fixed strike option token to exercise
    /// @param amount_       Amount of option tokens to exercise (also the number of payout tokens to receive)
    /// @dev                 Amount of quote tokens required to exercise is return from the exerciseCost() function
    /// @dev                 If the calling address is the token receiver address, then the amount of option tokens
    /// @dev                 are burned and collateral sent back to receiver, but proceeds are not required.
    /// @dev                 This allows unwrapping option tokens that aren't used prior to expiry.
    function exercise(FixedStrikeOptionToken optionToken_, uint256 amount_) external;

    /// @notice              Reclaim collateral from expired option tokens
    /// @notice              Only callable by the option token receiver address
    /// @param optionToken_  Fixed strike option token to reclaim collateral from
    function reclaim(FixedStrikeOptionToken optionToken_) external;

    /* ========== VIEWS ========== */

    /// @notice              Get the cost to exercise an amount of fixed strike option tokens
    /// @param optionToken_  Fixed strike option token to exercise
    /// @param amount_       Amount of option tokens to exercise
    /// @return token_       Token required to exercise (quoteToken for call, payoutToken for put)
    /// @return cost_        Amount of token_ required to exercise
    function exerciseCost(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external view returns (ERC20, uint256);

    /// @notice             Get the FixedStrikeOptionToken contract corresponding to the params, reverts if no token exists
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return token_      FixedStrikeOptionToken contract address
    function getOptionToken(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external view returns (FixedStrikeOptionToken);

    /// @notice             Get the hash ID of the fixed strike option token with these parameters
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return hash_       Hash ID of the fixed strike option token with these parameters
    function getOptionTokenHash(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external view returns (bytes32);
}