// SOYBOYS by Spacebar (@mrspcbr) | https://t.me/soyboyseth | https://twitter.com/soyboyseth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ERC20.sol";
contract SOYBOYS is Ownable, ERC20 {
    bool public limited;
    uint256 public maxWallet = 600000000000 * 10 ** decimals();
    address public uniswapV2Pair;
    constructor() ERC20("SOYBOYS", "SOY") {_mint(msg.sender, 100000000000000 * 10 ** decimals());}
    function setLimits(bool _limited, address _uniswapV2Pair) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        }
    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "TRADING_NOT_STARTED");
            return;
        }
        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxWallet, "MAX_WALLET_EXCEEDED");
        }
    }
}