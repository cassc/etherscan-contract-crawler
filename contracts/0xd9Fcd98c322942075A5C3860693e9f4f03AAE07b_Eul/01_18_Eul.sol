// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Eul is ERC20Votes, AccessControl {
    /// @notice The role assigned to users who can call admin/restricted functions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice The timestamp on and after which minting may occur.
    uint256 public mintingRestrictedBefore;

    /// @notice Minimum time between mints.
    uint256 public constant MINT_MIN_INTERVAL = 365 days;

    /// @notice Cap on the percentage of the total supply that can be minted at each mint.
    /// Denominated in percentage points (units out of 100000 for division precision).
    /// This value is set to the number e or Euler's number = 2.71828 (%)
    uint256 public constant MINT_MAX_PERCENT = 2718;

    /// @notice The recipient of the minted tokens
    address public treasury;

    /// EVENTS
    event TreasuryUpdated(address newTreasury);

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Caller does not have the ADMIN_ROLE"
        );
        _;
    }

    /**
    * @notice Constructor.
    *
    * @param  name                      The token name, i.e., Euler.
    * @param  symbol                    The token symbol, i.e., EUL.
    * @param  totalSupply_              Initial total token supply.
    * @param  mintingRestrictedBefore_   Timestamp, before which minting is not allowed.
    * @param  treasury_   Treasury address.
    */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_,
        uint256 mintingRestrictedBefore_,
        address treasury_
    ) ERC20(name, symbol) ERC20Permit(name) {
        require(
            mintingRestrictedBefore_ > block.timestamp,
            "MINTING_RESTRICTED_BEFORE_TOO_EARLY"
        );
        require(treasury_ != address(0), "cannot set or mint to zero treasury address");
        
        mintingRestrictedBefore = mintingRestrictedBefore_;
        treasury = treasury_;

        _mint(treasury_, totalSupply_);

        _setupRole(DEFAULT_ADMIN_ROLE, treasury_);
        _setupRole(ADMIN_ROLE, treasury_);
    }

    /**
    * @notice Mint new tokens only after the required time period has elapsed.
    * It will mint to the treasury address set by owner
    */
    function mint() external onlyAdmin {
        require(
            block.timestamp >= mintingRestrictedBefore,
            'MINT_TOO_EARLY'
        );
        require(
            treasury != address(0),
            'INVALID_TREASURY_ADDRESS'
        );

        uint256 amount = totalSupply() * MINT_MAX_PERCENT / 100000;
        require(amount > 0, "CANNOT_MINT_ZERO");

        // Update the next allowed minting time.
        mintingRestrictedBefore = block.timestamp + MINT_MIN_INTERVAL;

        // Mint the amount.
        _mint(treasury, amount);
        
    }

    /**
    * @notice Update the treasury address to receive minted tokens. 
    * Only callable by admins.
    * @param newTreasury The address to set as the new Treasury
    */
    function updateTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "cannot set or mint to zero treasury address");
        treasury = newTreasury;
        emit TreasuryUpdated(treasury);
    }

}