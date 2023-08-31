// SPDX-License-Identifier: MIT
pragma solidity = 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract MemeBuddha is ERC20, ERC20Burnable, Ownable {
    address public charityWallet;
    address public communityWallet;
    mapping (address => bool) public liquidityPools;

    constructor(address _charityWallet, address _communityWallet) ERC20("Meme Buddha", "MEBU") {
        require(_charityWallet != address(0), "Invalid charity wallet address");
        require(_communityWallet != address(0), "Invalid community wallet address");

        _mint(msg.sender, 108000000000 * 10 ** decimals());
        charityWallet = _charityWallet;
        communityWallet = _communityWallet;
    }

    function addLiquidityPool(address _liquidityPool) public onlyOwner {
        require(_liquidityPool != address(0), "Invalid liquidity pool address");
        liquidityPools[_liquidityPool] = true;
    }

    function removeLiquidityPool(address _liquidityPool) public onlyOwner {
        require(_liquidityPool != address(0), "Invalid liquidity pool address");
        liquidityPools[_liquidityPool] = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (liquidityPools[to] && from != charityWallet && from != communityWallet) {
            uint256 fee = amount * 6 / 100;
            uint256 distributeAmount = fee / 3;
            uint256 amountAfterFee = amount - fee;

            _burn(from, distributeAmount);
            _transfer(from, charityWallet, distributeAmount);

            // Calculate the remaining fee and distribute it to the community wallet
            uint256 remainingFee = fee - (2 * distributeAmount);
            _transfer(from, communityWallet, remainingFee);

            // Update the amount being transferred to the liquidity pool
            amount = amountAfterFee;
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}