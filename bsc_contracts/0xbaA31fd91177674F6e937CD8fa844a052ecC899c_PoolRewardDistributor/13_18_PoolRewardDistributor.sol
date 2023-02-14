// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./base/RolesManager.sol";
import "./interfaces/IMultipleRewardPool.sol";
import "./interfaces/ISingleRewardPool.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/ISnacksBase.sol";

contract PoolRewardDistributor is RolesManager {
    using SafeERC20 for IERC20;
    
    uint256 private constant BASE_PERCENT = 10000;
    uint256 private constant SENIORAGE_FEE_PERCENT = 1000;
    uint256 private constant ZOINKS_APE_SWAP_POOL_PERCENT = 2308;
    uint256 private constant ZOINKS_BI_SWAP_POOL_PERCENT = 2308;
    uint256 private constant ZOINKS_PANCAKE_SWAP_POOL_PERCENT = 5384;
    uint256 private constant SNACKS_PANCAKE_SWAP_POOL_PERCENT = 6667;
    uint256 private constant SNACKS_SNACKS_POOL_PERCENT = 3333;
    uint256 private constant BTC_SNACKS_PANCAKE_SWAP_POOL_PERCENT = 5714;
    uint256 private constant BTC_SNACKS_SNACKS_POOL_PERCENT = 4286;
    uint256 private constant ETH_SNACKS_PANCAKE_SWAP_POOL_PERCENT = 5714;
    uint256 private constant ETH_SNACKS_SNACKS_POOL_PERCENT = 4286;
    
    address public immutable busd;
    address public immutable router;
    address public zoinks;
    address public snacks;
    address public btcSnacks;
    address public ethSnacks;
    address public apeSwapPool;
    address public biSwapPool;
    address public pancakeSwapPool;
    address public snacksPool;
    address public lunchBox;
    address public seniorage;

    /**
    * @param busd_ Binance-Peg BUSD token address.
    * @param router_ Router contract address (from PancakeSwap DEX).
    */
    constructor(
        address busd_,
        address router_
    ) {
        busd = busd_;
        router = router_;
        IERC20(busd_).approve(router_, type(uint256).max);
    }
    
    /**
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param zoinks_ Zoinks token address.
    * @param snacks_ Snacks token address.
    * @param btcSnacks_ BtcSnacks token address.
    * @param ethSnacks_ EthSnacks token address.
    * @param apeSwapPool_ ApeSwapPool contract address.
    * @param biSwapPool_ BiSwapPool contract address.
    * @param pancakeSwapPool_ PancakeSwapPool contract address.
    * @param snacksPool_ SnacksPool contract address.
    * @param lunchBox_ LunchBox contract address.
    * @param seniorage_ Seniorage contract address.
    * @param authority_ Authorised address.
    */
    function configure(
        address zoinks_,
        address snacks_,
        address btcSnacks_,
        address ethSnacks_,
        address apeSwapPool_,
        address biSwapPool_,
        address pancakeSwapPool_,
        address snacksPool_,
        address lunchBox_,
        address seniorage_,
        address authority_
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        zoinks = zoinks_;
        snacks = snacks_;
        btcSnacks = btcSnacks_;
        ethSnacks = ethSnacks_;
        apeSwapPool = apeSwapPool_;
        biSwapPool = biSwapPool_;
        pancakeSwapPool = pancakeSwapPool_;
        snacksPool = snacksPool_;
        lunchBox = lunchBox_;
        seniorage = seniorage_;
        _grantRole(AUTHORITY_ROLE, authority_);
        if (IERC20(zoinks_).allowance(address(this), snacks_) == 0) {
            IERC20(zoinks_).approve(snacks_, type(uint256).max);
        }
    }
    
    /**
    * @notice Distributes rewards on pools and notifies them.
    * @dev Called by the authorised address once every 12 hours.
    * @param zoinksAmountOutMin_ Minimum expected amount of Zoinks token 
    * to be received after the exchange 90% of the total balance of Binance-Peg BUSD token.
    */
    function distributeRewards(uint256 zoinksAmountOutMin_) external whenNotPaused onlyRole(AUTHORITY_ROLE) {
        uint256 reward;
        uint256 seniorageFeeAmount;
        uint256 distributionAmount;
        uint256 zoinksBalance = IERC20(zoinks).balanceOf(address(this));
        if (zoinksBalance != 0) {
            address zoinksAddress = zoinks;
            // 10% of the balance goes to the Seniorage contract.
            seniorageFeeAmount = zoinksBalance * SENIORAGE_FEE_PERCENT / BASE_PERCENT;
            IERC20(zoinksAddress).safeTransfer(seniorage, seniorageFeeAmount);
            distributionAmount = zoinksBalance - seniorageFeeAmount;
            // 23.08% of the distribution amount goes to the ApeSwapPool contract.
            reward = distributionAmount * ZOINKS_APE_SWAP_POOL_PERCENT / BASE_PERCENT;
            IERC20(zoinksAddress).safeTransfer(apeSwapPool, reward);
            ISingleRewardPool(apeSwapPool).notifyRewardAmount(reward);
            // 23.08% of the distribution amount goes to the BiSwapPool contract.
            reward = distributionAmount * ZOINKS_BI_SWAP_POOL_PERCENT / BASE_PERCENT;
            IERC20(zoinksAddress).safeTransfer(biSwapPool, reward);
            ISingleRewardPool(biSwapPool).notifyRewardAmount(reward);
            // 53.84% of the distribution amount goes to the PancakeSwapPool contract.
            reward = distributionAmount * ZOINKS_PANCAKE_SWAP_POOL_PERCENT / BASE_PERCENT;
            IERC20(zoinksAddress).safeTransfer(pancakeSwapPool, reward);
            IMultipleRewardPool(pancakeSwapPool).notifyRewardAmount(zoinksAddress, reward);
        }
        uint256 snacksBalance = IERC20(snacks).balanceOf(address(this));
        if (snacksBalance != 0) {
            address snacksAddress = snacks;
            // 10% of the balance goes to the Seniorage contract.
            seniorageFeeAmount = snacksBalance * SENIORAGE_FEE_PERCENT / BASE_PERCENT;
            IERC20(snacksAddress).safeTransfer(seniorage, seniorageFeeAmount);
            distributionAmount = snacksBalance - seniorageFeeAmount;
            // 66.67% of the distribution amount goes to the PancakeSwapPool contract.
            reward = distributionAmount * SNACKS_PANCAKE_SWAP_POOL_PERCENT / BASE_PERCENT;
            IERC20(snacksAddress).safeTransfer(pancakeSwapPool, reward);
            IMultipleRewardPool(pancakeSwapPool).notifyRewardAmount(snacksAddress, reward);
            // 33.33% of the distribution amount goes to the SnacksPool contract.
            reward = distributionAmount * SNACKS_SNACKS_POOL_PERCENT / BASE_PERCENT;
            IERC20(snacksAddress).safeTransfer(snacksPool, reward);
            IMultipleRewardPool(snacksPool).notifyRewardAmount(snacksAddress, reward);
        }
        uint256 btcSnacksBalance = IERC20(btcSnacks).balanceOf(address(this));
        if (btcSnacksBalance != 0) {
            address btcSnacksAddress = btcSnacks;
            // 10% of the balance goes to the Seniorage contract.
            seniorageFeeAmount = btcSnacksBalance * SENIORAGE_FEE_PERCENT / BASE_PERCENT;
            IERC20(btcSnacksAddress).safeTransfer(seniorage, seniorageFeeAmount);
            distributionAmount = btcSnacksBalance - seniorageFeeAmount;
            // 57.14% of the distribution amount goes to the PancakeSwapPool contract.
            reward = distributionAmount * BTC_SNACKS_PANCAKE_SWAP_POOL_PERCENT / BASE_PERCENT;
            IERC20(btcSnacksAddress).safeTransfer(pancakeSwapPool, reward);
            IMultipleRewardPool(pancakeSwapPool).notifyRewardAmount(btcSnacksAddress, reward);
            // 42.86% of the distribution amount goes to the SnacksPool contract.
            reward = distributionAmount * BTC_SNACKS_SNACKS_POOL_PERCENT / BASE_PERCENT;
            IERC20(btcSnacksAddress).safeTransfer(snacksPool, reward);
            IMultipleRewardPool(snacksPool).notifyRewardAmount(btcSnacksAddress, reward);
        }
        uint256 ethSnacksBalance = IERC20(ethSnacks).balanceOf(address(this));
        if (ethSnacksBalance != 0) {
            address ethSnacksAddress = ethSnacks;
            // 10% of the balance goes to the Seniorage contract.
            seniorageFeeAmount = ethSnacksBalance * SENIORAGE_FEE_PERCENT / BASE_PERCENT;
            IERC20(ethSnacksAddress).safeTransfer(seniorage, seniorageFeeAmount);
            distributionAmount = ethSnacksBalance - seniorageFeeAmount;
            // 57.14% of the distribution amount goes to the PancakeSwapPool contract.
            reward = distributionAmount * ETH_SNACKS_PANCAKE_SWAP_POOL_PERCENT / BASE_PERCENT;
            IERC20(ethSnacksAddress).safeTransfer(pancakeSwapPool, reward);
            IMultipleRewardPool(pancakeSwapPool).notifyRewardAmount(ethSnacksAddress, reward);
            // 42.86% of the distribution amount goes to the SnacksPool contract.
            reward = distributionAmount * ETH_SNACKS_SNACKS_POOL_PERCENT / BASE_PERCENT;
            IERC20(ethSnacksAddress).safeTransfer(snacksPool, reward);
            IMultipleRewardPool(snacksPool).notifyRewardAmount(ethSnacksAddress, reward);
        }
        uint256 busdBalance = IERC20(busd).balanceOf(address(this));
        if (busdBalance != 0) {
            // 10% of the balance goes to the Seniorage contract.
            seniorageFeeAmount = busdBalance * SENIORAGE_FEE_PERCENT / BASE_PERCENT;
            IERC20(busd).safeTransfer(seniorage, seniorageFeeAmount);
            // Exchange 100% of the distribution amount on Zoinks tokens.
            distributionAmount = busdBalance - seniorageFeeAmount;
            address[] memory path = new address[](2);
            path[0] = busd;
            path[1] = zoinks;
            uint256[] memory amounts = IRouter(router).swapExactTokensForTokens(
                distributionAmount,
                zoinksAmountOutMin_,
                path,
                address(this),
                block.timestamp
            );
            uint256 snacksAmount = ISnacksBase(snacks).mintWithPayTokenAmount(amounts[1]);
            IERC20(snacks).safeTransfer(lunchBox, snacksAmount);
            ISingleRewardPool(lunchBox).notifyRewardAmount(snacksAmount);
        }
    }
}