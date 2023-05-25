// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "../vendored/mixins/ERC20.sol";
import "../vendored/mixins/draft-ERC20Permit.sol";

/// @dev Contract contains the logic for minting new tokens
/// @title Mintable Token
/// @author CoW Protocol Developers
contract InflationaryToken is ERC20, ERC20Permit {
    /// @dev Defines the cowDao address that is allowed to mint new tokens
    address public immutable cowDao;
    /// @dev Defines how frequently inflation can be triggered: Once a year
    uint256 public constant TIME_BETWEEN_MINTINGS = 365 days;
    /// @dev Defines the maximal inflation per year
    uint256 public constant MAX_YEARLY_INFLATION = 3;
    /// @dev Stores the timestamp of the last inflation event
    uint256 public timestampLastMinting = 0;

    /// @dev Error caused by an attempt to mint too many tokens.
    error ExceedingMintCap();
    /// @dev Error caused by calling the mint function more than once within one year.
    error AlreadyInflated();
    /// @dev Error caused by calling the mint function from a non-cowDao account.
    error OnlyCowDao();

    modifier onlyCowDao() {
        if (msg.sender != cowDao) {
            revert OnlyCowDao();
        }
        _;
    }

    constructor(
        address initialTokenHolder,
        address _cowDao,
        uint256 totalSupply,
        string memory erc20Name,
        string memory erc20Symbol
    ) ERC20(erc20Name, erc20Symbol) ERC20Permit(erc20Name) {
        _mint(initialTokenHolder, totalSupply);
        cowDao = _cowDao;
        // solhint-disable-next-line not-rely-on-time
        timestampLastMinting = block.timestamp;
    }

    /// @dev This function allows to mint new tokens
    /// @param target The address that should receive the new tokens
    /// @param amount The amount of tokens to be minted.
    function mint(address target, uint256 amount) external onlyCowDao {
        if (amount > (totalSupply() * MAX_YEARLY_INFLATION) / 100) {
            revert ExceedingMintCap();
        }
        // solhint-disable-next-line not-rely-on-time
        if (timestampLastMinting + TIME_BETWEEN_MINTINGS > block.timestamp) {
            revert AlreadyInflated();
        }
        timestampLastMinting = block.timestamp; // solhint-disable-line not-rely-on-time
        _mint(target, amount);
    }
}