// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Noggles is ERC20, ERC20Burnable, Ownable {
    /// @dev Defines how frequently inflation can be triggered: Once a year
    uint256 public constant TIME_BETWEEN_MINTINGS = 365 days;
    /// @dev Defines the maximal inflation per year defined as k%, i.e. 1000 is 1%.
    uint256 public constant MAX_YEARLY_INFLATION = 1_690;
    /// @dev Stores the timestamp of the last inflation event
    uint256 public timestampLastMinting = 0;

    constructor() ERC20("Noggles", "NOGS") {
        _mint(msg.sender, 69_000_000_000 * 10 ** decimals());

        // solhint-disable-next-line not-rely-on-time
        timestampLastMinting = block.timestamp;
    }

    /// @dev This function allows to mint new tokens once every TIME_BETWEEN_MINTINGS and mints INFLATION.
    /// @param target The address that should receive the new tokens
    function mint(address target) external onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(
            block.timestamp - timestampLastMinting >= TIME_BETWEEN_MINTINGS,
            "already inflated"
        );
        // solhint-disable-next-line not-rely-on-time
        timestampLastMinting = block.timestamp;
        uint256 amount = (totalSupply() * MAX_YEARLY_INFLATION) / 100_000;
        _mint(target, amount);
    }
}