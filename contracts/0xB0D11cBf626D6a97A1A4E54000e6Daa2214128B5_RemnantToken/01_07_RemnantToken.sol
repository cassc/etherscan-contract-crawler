// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./extensions/BP.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RemnantToken is ERC20, Ownable, BP {

    // For team, staking, P2E ecosystem, other
    uint256 public constant INITIAL_AMOUNT_ECOSYSTEM = 2_500_000_000; // 25%
    uint256 public constant INITIAL_AMOUNT_BACKERS = 2_500_000_000; // 25%
    uint256 public constant INITIAL_AMOUNT_STAKING = 1_500_000_000; // 15%
    uint256 public constant INITIAL_AMOUNT_TEAM = 1_000_000_000; // 10%
    uint256 public constant INITIAL_AMOUNT_LIQUIDITY = 850_000_000; // 8.5%
    uint256 public constant INITIAL_AMOUNT_MARKETING = 700_000_000; // 7%
    uint256 public constant INITIAL_AMOUNT_TREASURY = 500_000_000; // 5%
    uint256 public constant INITIAL_AMOUNT_DEVELOPMENT = 450_000_000; // 4.5%
    
    address public constant ADDRESS_ECOSYSTEM = 0x88e50b87F39E5abb4ef94eC3794314f74F31c63a;
    address public constant ADDRESS_BACKERS = 0x44e13ED3Aae3bbB4f3cDe8acaAF4d25036CC270a;
    address public constant ADDRESS_STAKING = 0xc5522C9F6F3c9CD87bF74EDe5424dcF3a4b8b29D;
    address public constant ADDRESS_TEAM = 0x73b4eFF6Af5C7EA220403B009fFf0c0dA2d19C67;
    address public constant ADDRESS_LIQUIDITY = 0x65B903979CD209233a481B29cdD1f030612dE605;
    address public constant ADDRESS_MARKETING = 0xaBe19e6fd481c424b00D3a8aF70C77d7aE55E70d;
    address public constant ADDRESS_TREASURY = 0x4A8Cd013879c4D48C96EAA50dE9Af2969e297586;
    address public constant ADDRESS_DEVELOPMENT = 0x7496e1D91f7Dcad9a4889a9A023736850300fE97;

    constructor() ERC20("Remnant", "REMN") {
        _mint(ADDRESS_ECOSYSTEM, INITIAL_AMOUNT_ECOSYSTEM * 10 ** 18);
        _mint(ADDRESS_BACKERS, INITIAL_AMOUNT_BACKERS * 10 ** 18);
        _mint(ADDRESS_STAKING, INITIAL_AMOUNT_STAKING * 10 ** 18);
        _mint(ADDRESS_TEAM, INITIAL_AMOUNT_TEAM * 10 ** 18);
        _mint(ADDRESS_LIQUIDITY, INITIAL_AMOUNT_LIQUIDITY * 10 ** 18);
        _mint(ADDRESS_MARKETING, INITIAL_AMOUNT_MARKETING * 10 ** 18);
        _mint(ADDRESS_TREASURY, INITIAL_AMOUNT_TREASURY * 10 ** 18);
        _mint(ADDRESS_DEVELOPMENT, INITIAL_AMOUNT_DEVELOPMENT * 10 ** 18);
    }

    /**
     * @dev Check before token transfer if bot protection is on, to block suspicious transactions
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        // Bot/snipe protection requirements if bp (bot protection) is on, and is not already permanently disabled
        if (bpEnabled) {
            if (!bpPermanentlyDisabled && msg.sender != owner()) { // Save gas, don't check if don't pass bpEnabled
                require(!bpBlacklisted[from] && !bpBlacklisted[to], "BP: Account is blacklisted"); // Must not be blacklisted
                if (bpTradingBlocked) {
                    if (from != bpDistributionAddr) // Token distributor bypasses block
                    {
                        if (to != bpWhitelistedStakingPool && to != bpWhitelistAddr) {
                            revert Blocked(); // If trading is blocked, revert if not sending to the whitelisted address (i.e. Staking pool)
                        }
                    }
                }
                require(tx.gasprice <= bpMaxGas, "BP: Gas setting exceeds allowed limit"); // Must set gas below allowed limit
            
                // If user is buying (from swap), check that the buy amount is less than the limit (this will not block other transfers unrelated to swap liquidity)
                if (bpSwapPairRouterPool == from) {
                    require(amount <= bpMaxBuyAmount, "BP: Buy exceeds allowed limit"); // Cannot buy more than allowed limit
                    require(bpAddressTimesTransacted[to] < bpAllowedNumberOfTx, "BP: Exceeded number of allowed transactions");
                    if (!bpTradingEnabled) {
                        bpBlacklisted[to] = true; // Blacklist wallet if it tries to trade (i.e. bot automatically trying to snipe liquidity)
                        revert SwapNotEnabledYet(); // Revert with error message
                    } else {
                        bpAddressTimesTransacted[to] += 1; // User has passed transaction conditions, so add to mapping (to limit user to 2 transactions)
                    }
                // If user is selling (from swap), check that the sell amount is less than the limit. The code is mostly repeated to avoid declaring variable and wasting gas.
                } else if (bpSwapPairRouterPool == to) {
                    require(amount <= bpMaxSellAmount, "BP: Sell exceeds limit"); // Cannot sell more than allowed limit
                    require(bpAddressTimesTransacted[from] < bpAllowedNumberOfTx, "BP: Exceeded number of allowed transactions");
                    if (!bpTradingEnabled) {
                        bpBlacklisted[from] = true; // Blacklist wallet if it tries to trade (i.e. bot automatically trying to snipe liquidity)
                        revert SwapNotEnabledYet(); // Revert with error message
                    } else {
                        bpAddressTimesTransacted[from] += 1; // User has passed transaction conditions, so add to mapping (to limit user to 2 transactions)
                    }
                }
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }

}