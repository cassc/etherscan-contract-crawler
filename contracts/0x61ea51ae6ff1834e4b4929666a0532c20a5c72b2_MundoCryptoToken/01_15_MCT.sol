// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title   MundoCryptoToken
 * @notice  MundoCryptoToken based on the tokenomics.
 *          Token Total Supply:          1_000_000_000
 *          Airdrop:                     6% of Total Supply
 *          Future Private Sale:         13% of Total Supply
 *          Seed Phase:                  6% of Total Supply
 *          Foundation Treasury:         13% of Total Supply
 *          Ecosystem Incentives:        33% of Total Supply
 *          Marketing:                   12% of Total Supply
 *          Partners:                    5% of Total Supply
 *          Team:                        9%  of Total Supply
 *          Liquidity:                   3%  of Total Supply
 */
contract MundoCryptoToken is ERC20, ERC20Permit, ERC20Votes {
    constructor()
        ERC20("MundoCryptoToken", "MCT")
        ERC20Permit("MundoCryptoToken")
    {
        // Future Private Sale
        // Seed Sale
        // Ecosystem Incentives
        // Foundation Treasury
        // Marketing
        // Advisors
        // Team
        _mint(0x1043B6106fD10fDa7DD7Ce58cd3fa8dB62A88eFe, 910000000 * 10**18);

        // Liquidity
        _mint(0x314C6086EEA1aC5Bc36a5E9AAB531EB921B102eD, 10000000 * 10**18);
        _mint(0xE6A268af321A824fed9689542025F7d9370066e5, 10000000 * 10**18);
        _mint(0xE7f5C33dBB90997bF8B7084B8195B5e13113F8a1, 10000000 * 10**18);

        // Airdrop
        _mint(0x1E9EEef041a3e89E2539Cd8f49f3Bc1FbC8Eb7c4, 30000000 * 10**18);
        _mint(0x75abf27b69C8d202419026487498BC57ccc70dCD, 30000000 * 10**18);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}