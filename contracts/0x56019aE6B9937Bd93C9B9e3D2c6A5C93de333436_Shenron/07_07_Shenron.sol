// SPDX-License-Identifier: MIT
// Telegram: https://t.me/shenronERC20entry
// Twitter: https://twitter.com/Shenron_ERC20
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Shenron is ERC20, Ownable {
    IUniswapV2Factory private immutable factory;

    address public pair;
    uint256 public maxWallet;

    constructor(address _cexWAllet, address _devWallet) ERC20("Shenron", "SHENRON") {
        uint256 _totalSupply = 1_000_000* 1e18;
        maxWallet = (_totalSupply * 2) / 100;
        _mint(_cexWAllet, 70_000* 1e18);
        _mint(_devWallet, 100_000* 1e18);
        _mint(_msgSender(), 830_000* 1e18); // LP
        factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        pair = factory.createPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this));
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        checkWalletLimit(to, amount);
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if (
            recipient != owner() &&
            recipient != address(this) &&
            recipient != pair
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= maxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

}