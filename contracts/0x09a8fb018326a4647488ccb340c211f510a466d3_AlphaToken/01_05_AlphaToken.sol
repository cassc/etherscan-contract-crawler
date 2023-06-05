// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IAlphaToken} from "$/interfaces/IAlphaToken.sol";

/// @title  $ALPHA
/// @author Aleph Retamal <github.com/alephao>, Gustavo Tiago <github.com/gutiago>
contract AlphaToken is IAlphaToken, ERC20, Ownable {
    /// @notice Addresses with special access to use mint/burn functions
    mapping(address => bool) private allowed;

    modifier onlyAllowed() {
        if (!allowed[msg.sender]) revert NotAllowed();
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("ALPHA", "ALPHA", 18) {}

    /// @notice     Mints an amount of tokens to an address.
    ///             Caller has to be allowed.
    function mint(address addr, uint256 amount) external onlyAllowed {
        _mint(addr, amount);
    }

    /// @notice     Burn an amount of tokens from an address.
    ///             Caller has to be a allowed.
    function burn(address from, uint256 amount) external onlyAllowed {
        _burn(from, amount);
    }

    /// @notice     Set or unset an address as a controller.
    ///             Owner Only.
    function setAllowed(address addr, bool isAllowed) external onlyOwner {
        if (allowed[addr] == isAllowed) revert NotChanged();
        allowed[addr] = isAllowed;
    }
}