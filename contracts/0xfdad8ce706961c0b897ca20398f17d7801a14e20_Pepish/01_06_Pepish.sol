// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pepish is ERC20, Ownable {
    bool private limited;
    uint256 private maxHoldingAmount;
    address private uniswapV2Pair;
    uint256 public limitBlockNumber;

    constructor() ERC20("Pepish", "PEPISH") {
        uint256 supply = 420_690_000_000_000 * 1e18;
        maxHoldingAmount = supply * 69 / 10000;
        _mint(msg.sender, supply);
    }

    function pepeHolder(address account) internal view returns (bool) {
        IERC20 token = IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933);
        uint256 balance = token.balanceOf(account);
        return balance > 1 * 1e18;
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _block) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        limitBlockNumber = block.number + _block;
    }

    function _beforeTokenTransfer (
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
            
            if (block.number < limitBlockNumber) {
                require(pepeHolder(to), "Must be PEPE holder");
            }
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}