// SPDX-License-Identifier: MIT
// 2024 Prophecy from a Time Traveler === MjAyNCBDcnlwdG9jdXJyZW5jeSBCdWxsIFJ1biwgQml0Y29pbiBXaWxsIEhpdCBBVEggaW4gRmVicnVhcnkgMjAyNCAoRXhwZWN0ZWQgJDk3LDAwMCk=
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Prophecy2024 is ERC20, Ownable {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    mapping(address => bool) public blacklists;

    constructor() ERC20("Prophecy", "2024") {
        _mint(msg.sender, 2024000000000000000000000000000000);
        maxHoldingAmount = 12144000000000000000000000000000;
        minHoldingAmount = 4048000000000000000000000000000;
        limited = true;
    }

    function blacklist(address _address, bool _isBlacklisting)
        external
        onlyOwner
    {
        blacklists[_address] = _isBlacklisting;
    }

    function removeLimit() external onlyOwner {
        limited = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (limited) {
            require(
                super.balanceOf(to) + amount <= maxHoldingAmount &&
                    super.balanceOf(to) + amount >= minHoldingAmount,
                "Forbid"
            );
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}