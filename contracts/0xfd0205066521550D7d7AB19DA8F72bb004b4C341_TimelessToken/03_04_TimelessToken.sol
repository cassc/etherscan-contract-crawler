// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC20Mintable} from "./interfaces/IERC20Mintable.sol";

contract TimelessToken is ERC20, Owned, IERC20Mintable {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error TimelessToken__NotMinter();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event SetMinter(address indexed minter);

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 public constant INITIAL_SUPPLY = 550_000_000 ether;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice The address that has minting rights. Should be the options token contract.
    address public minter;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory name_, string memory symbol_, address owner_, address minter_)
        ERC20(name_, symbol_, 18)
        Owned(owner_)
    {
        // mint the initial token supply to the owner
        _mint(owner_, INITIAL_SUPPLY);

        minter = minter_;
    }

    /// -----------------------------------------------------------------------
    /// IERC20Mintable
    /// -----------------------------------------------------------------------

    /// @notice Called by the minter to mint tokens
    /// @param to The address that will receive the minted tokens
    /// @param amount The amount of tokens that will be minted
    function mint(address to, uint256 amount) external virtual override {
        /// -----------------------------------------------------------------------
        /// Verification
        /// -----------------------------------------------------------------------

        if (msg.sender != minter) revert TimelessToken__NotMinter();

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // skip if amount is zero
        if (amount == 0) return;

        // mint tokens
        _mint(to, amount);
    }

    /// -----------------------------------------------------------------------
    /// Owner functions
    /// -----------------------------------------------------------------------

    /// @notice Sets the minter address. Only callable by the owner.
    /// @param minter_ The new minter
    function setMinter(address minter_) external onlyOwner {
        minter = minter_;
        emit SetMinter(minter_);
    }
}