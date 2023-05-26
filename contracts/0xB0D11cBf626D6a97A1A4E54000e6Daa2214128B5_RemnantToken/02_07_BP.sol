// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

error SwapNotEnabledYet();
error Blocked();

contract BP is Ownable {
    
    // For bp (bot protection), to deter liquidity sniping, enabled during first moments of each swap liquidity (ie. Uniswap, Quickswap, etc)
    uint256 public bpAllowedNumberOfTx;     // Max allowed number of buys/sells on swap during bp per address
    uint256 public bpMaxGas;                // Max gwei per trade allowed during bot protection
    uint256 public bpMaxBuyAmount;          // Max number of tokens an address can buy during bot protection
    uint256 public bpMaxSellAmount;         // Max number of tokens an address can sell during bot protection
    bool public bpEnabled;                  // Bot protection, on or off
    bool public bpTradingEnabled;           // Enables trading during bot protection period
    bool public bpPermanentlyDisabled;      // Starts false, but when set to true, is permanently true. Let's public see that it is off forever.
    address public bpSwapPairRouterPool;           // ie. Uniswap V2 ETH-REMN Pool (router) for bot protected buy/sell, add after pool established.
    bool public bpTradingBlocked;            // Token might want to block trading until liquidity is added
    address public bpWhitelistedStakingPool;    // Whitelist staking pool so users can send to it regardless of trading block
    address public bpWhitelistAddr;             // Whitelist an additional address (i.e. Another staking pool)
    address public bpDistributionAddr;          // Distribution address, which bypasses any bot protection trading block
    mapping (address => uint256) public bpAddressTimesTransacted;   // Mapped value counts number of times transacted (2 max per address during bp)
    mapping (address => bool) public bpBlacklisted;                 // If wallet tries to trade after liquidity is added but before owner sets trading on, wallet is blacklisted

    /**
     * @dev Toggles bot protection, blocking suspicious transactions during liquidity events.
     */
    function bpToggleOnOff() external onlyOwner {
        bpEnabled = !bpEnabled;
    }

    /**
     * @dev Sets max gwei allowed in transaction when bot protection is on.
     */
    function bpSetMaxGwei(uint256 gweiAmount) external onlyOwner {
        bpMaxGas = gweiAmount;
    }

    /**
     * @dev Sets max buy value when bot protection is on.
     */
    function bpSetMaxBuyValue(uint256 val) external onlyOwner {
        bpMaxBuyAmount = val;
    }

     /**
     * @dev Sets max sell value when bot protection is on.
     */
    function bpSetMaxSellValue(uint256 val) external onlyOwner {
        bpMaxSellAmount = val;
    }

    /**
     * @dev Sets swap pair pool address (i.e. Uniswap V2 ETH-REMN pool, for bot protection)
     */
    function bpSetSwapPairPool(address addr) external onlyOwner {
        bpSwapPairRouterPool = addr;
    }

    /**
     * @dev Sets staking pool address so that users are not blocked from staking during trading block
     */
    function bpSetWhitelistedStakingPool(address addr) external onlyOwner {
        bpWhitelistedStakingPool = addr;
    }

    /**
     * @dev Sets a whitelist address that users can send to during trading block (i.e. sale event or additional stkaing pool)
     */
    function bpSetWhitelistedAddress(address addr) external onlyOwner {
        bpWhitelistAddr = addr;
    }

    /**
     * @dev Sets the distribution address
     */
    function bpSetDistributionAddress(address addr) external onlyOwner {
        bpDistributionAddr = addr;
    }

    /**
     * @dev Turns off bot protection permanently.
     */
    function bpDisablePermanently() external onlyOwner {
        bpEnabled = false;
        bpPermanentlyDisabled = true;
    }

    function bpAddBlacklist(address addr) external onlyOwner {
        bpBlacklisted[addr] = true;
    }

    function bpRemoveBlacklist(address addr) external onlyOwner {
        bpBlacklisted[addr] = false;
    }

    /**
     * @dev Toggles bot protection trading (requires bp not permanently disabled)
     */
    function bpToggleTrading() external onlyOwner {
        require(!bpPermanentlyDisabled, "Cannot toggle when bot protection is already disabled permanently");
        bpTradingEnabled = !bpTradingEnabled;
    }

    /**
     * @dev Toggles token transfers (all trading), during bp
     */
    function bpToggleTradingBlock() external onlyOwner {
        bpTradingBlocked = !bpTradingBlocked;
    }

}