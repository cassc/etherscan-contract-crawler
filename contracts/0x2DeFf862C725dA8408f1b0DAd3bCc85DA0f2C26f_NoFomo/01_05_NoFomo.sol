// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NoFomo is ERC20 {

    address admin;
    bool limited;
    address uniswapV2Pair;
    uint256 maxHoldingAmount;

    constructor() ERC20("NoFomo", "NOFOMO") {
        _mint(msg.sender, 69000000 ether);
        limited = true;
        maxHoldingAmount = 3450000 ether;
        admin = msg.sender;
    }

    function removeAdmin() external {
        require(msg.sender == admin, "Not allowed");
        admin = address(0);
    }

    function setPair(address _uniswapV2Pair) external  {
        require(msg.sender == admin, "Not allowed");
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setLimits(bool _limited, uint256 _maxHoldingAmount) external  {
        require(msg.sender == admin, "Not allowed");
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {

        if (uniswapV2Pair == address(0)) {
            require(from == admin || to == admin || from == address(0), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }
}