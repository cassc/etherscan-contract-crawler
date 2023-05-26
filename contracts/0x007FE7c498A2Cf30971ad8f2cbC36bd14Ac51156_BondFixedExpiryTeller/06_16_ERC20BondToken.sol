// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {CloneERC20} from "./lib/CloneERC20.sol";

/// @title ERC20 Bond Token
/// @notice ERC20 Bond Token Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The ERC20 Bond Token contract is issued by a Fixed Expiry Teller to
///      represent bond positions until they vest. Bond tokens can be redeemed for
//       the underlying token 1:1 at or after expiry.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Oighty, Zeus, Potted Meat, indigo
contract ERC20BondToken is CloneERC20 {
    /* ========== ERRORS ========== */
    error BondToken_OnlyTeller();

    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The token to be redeemed when the bond vests
    /// @return _underlying The address of the underlying token
    function underlying() external pure returns (ERC20 _underlying) {
        return ERC20(_getArgAddress(0x41));
    }

    /// @notice Timestamp at which the BondToken can be redeemed for the underlying
    /// @return _expiry The vest start timestamp
    function expiry() external pure returns (uint48 _expiry) {
        return uint48(_getArgUint256(0x55));
    }

    /// @notice Address of the Teller that created the token
    function teller() internal pure returns (address _teller) {
        return _getArgAddress(0x75);
    }

    /* ========== MINT/BURN ========== */

    function mint(address to, uint256 amount) external {
        if (msg.sender != teller()) revert BondToken_OnlyTeller();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != teller()) revert BondToken_OnlyTeller();
        _burn(from, amount);
    }
}