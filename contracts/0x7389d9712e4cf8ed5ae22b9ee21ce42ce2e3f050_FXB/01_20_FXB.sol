// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =============================== FXB ================================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { IFrax } from "./interfaces/IFrax.sol";
import { FXBFactory } from "./FXBFactory.sol";

/// @title FXB
/// @notice  The FXB token can be redeemed for 1 FRAX at a later date. Created via a factory contract.
contract FXB is ERC20, ERC20Permit {
    // =============================================================================================
    // Storage
    // =============================================================================================

    /// @notice Factory contract for generating FXBs
    FXBFactory public immutable FXB_FACTORY;

    /// @notice The Frax token contract
    IFrax public immutable FRAX;

    /// @notice Timestamp of bond maturity
    uint256 public immutable MATURITY_TIMESTAMP;

    /// @notice Total amount of FXB redeemed
    uint256 public totalFXBRedeemed;

    // =============================================================================================
    // Structs
    // =============================================================================================

    /// @notice Bond Information
    /// @param symbol The symbol of the bond
    /// @param name The name of the bond
    /// @param maturityTimestamp Timestamp the bond will mature
    struct BondInfo {
        string symbol;
        string name;
        uint256 maturityTimestamp;
    }

    // =============================================================================================
    // Constructor
    // =============================================================================================

    /// @notice Called by the factory
    /// @param _symbol The symbol of the bond
    /// @param _name The name of the bond
    /// @param _maturityTimestamp Timestamp the bond will mature and be redeemable
    constructor(
        address _fraxErc20,
        string memory _symbol,
        string memory _name,
        uint256 _maturityTimestamp
    ) ERC20(_symbol, _name) ERC20Permit(_symbol) {
        // Set the FRAX address
        FRAX = IFrax(_fraxErc20);

        // Set the factory
        FXB_FACTORY = FXBFactory(msg.sender);

        // Set the maturity timestamp
        MATURITY_TIMESTAMP = _maturityTimestamp;
    }

    // =============================================================================================
    // View functions
    // =============================================================================================

    /// @notice Returns summary information about the bond
    /// @return BondInfo Summary of the bond
    function bondInfo() external view returns (BondInfo memory) {
        return BondInfo({ symbol: symbol(), name: name(), maturityTimestamp: MATURITY_TIMESTAMP });
    }

    /// @notice Returns a boolean representing whether a bond can be redeemed
    /// @return _isRedeemable If the bond is redeemable
    function isRedeemable() public view returns (bool _isRedeemable) {
        _isRedeemable = (block.timestamp >= MATURITY_TIMESTAMP);
    }

    // =============================================================================================
    // Public functions
    // =============================================================================================

    /// @notice Mints a specified amount of tokens to the account, requires caller to approve on the FRAX contract in an amount equal to the minted amount
    /// @param _to The account to receive minted tokens
    /// @param _amount The amount of the token to mint
    function mint(address _to, uint256 _amount) public {
        // NOTE: Allow minting after expiry

        // Effects: Give the FXB to the recipient
        _mint({ account: _to, amount: _amount });

        // Interactions: Take 1-to-1 FRAX from the user
        FRAX.transferFrom({ sender: msg.sender, recipient: address(this), amount: _amount });
    }

    /// @notice Redeems FXB 1-to-1 for FRAX
    /// @param _recipient Recipient of the FRAX
    /// @param _redeemAmount Amount to redeem
    function burn(address _recipient, uint256 _redeemAmount) public {
        // Make sure the bond has matured
        if (!isRedeemable()) revert BondNotRedeemable();

        // Effects: Update redeem tracking
        totalFXBRedeemed += _redeemAmount;

        // Effects: Burn the FXB from the user
        _burn({ account: msg.sender, amount: _redeemAmount });

        // Interactions: Give FRAX to the recipient
        FRAX.transfer({ recipient: _recipient, amount: _redeemAmount });
    }

    // ==============================================================================
    // Errors
    // ==============================================================================

    /// @notice Thrown if the bond hasn't matured yet, or redeeming is paused
    error BondNotRedeemable();
}