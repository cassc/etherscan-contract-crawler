// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract JeromePowell is ERC20, Ownable {
    bool public maxBuyEnabled;
    uint256 public maxBuyAmount;
    address public pair;

    mapping(address => bool) public blacklists;

    constructor() ERC20("Jerome Powell Token", "JPOW") {
        uint256 supply = 177_600_000_000_000 * 1e9;
        maxBuyEnabled = true;
        maxBuyAmount = supply / 1000; // 0.1% of supply
        _mint(msg.sender, supply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (pair == address(0)) {
            require(from == owner() || to == owner(), "Trading is not started");
            return;
        }

        if (maxBuyEnabled && from == pair) {
            require(
                amount <= maxBuyAmount,
                "You can't buy or sell more than % of the supply at once"
            );
        }
    }

    function removeLimits() public onlyOwner {
        maxBuyEnabled = false;
    }

    function setMaxBuyAmount(uint256 _amount) public onlyOwner {
        maxBuyAmount = _amount;
    }

    function setPairAddress(address _pair) external onlyOwner {
        pair = _pair;
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }
}