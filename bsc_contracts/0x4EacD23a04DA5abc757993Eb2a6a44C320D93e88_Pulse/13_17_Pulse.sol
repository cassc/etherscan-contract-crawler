// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./base/RolesManager.sol";
import "./interfaces/IMultipleRewardPool.sol";
import "./interfaces/ISnacksBase.sol";
import "./interfaces/IRouter.sol";

contract Pulse is RolesManager {
    using SafeERC20 for IERC20;

    uint256 private constant BASE_PERCENT = 10000;
    uint256 private constant BTC_SNACKS_SENIORAGE_PERCENT = 5000;
    uint256 private constant ETH_SNACKS_SENIORAGE_PERCENT = 5000;
    uint256 private constant SNACKS_DISTRIBUTION_PERCENT = 1000;
    uint256 private constant ZOINKS_DISTRIBUTION_PERCENT = 1000;

    address public immutable busd;
    address public immutable router;
    address public cakeLP;
    address public zoinks;
    address public snacks;
    address public btcSnacks;
    address public ethSnacks;
    address public pancakeSwapPool;
    address public snacksPool;
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
    * @param cakeLP_ Pancake LPs token address.
    * @param zoinks_ Zoinks token address.
    * @param snacks_ Snacks token address.
    * @param btcSnacks_ BtcSnacks token address.
    * @param ethSnacks_ EthSnacks token address.
    * @param pancakeSwapPool_ PancakeSwapPool contract address.
    * @param snacksPool_ SnacksPool contract address.
    * @param seniorage_ Seniorage contract address.
    * @param authority_ Authorised address.
    */
    function configure(
        address cakeLP_,
        address zoinks_,
        address snacks_,
        address btcSnacks_,
        address ethSnacks_,
        address pancakeSwapPool_,
        address snacksPool_,
        address seniorage_,
        address authority_
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        cakeLP = cakeLP_;
        zoinks = zoinks_;
        snacks = snacks_;
        btcSnacks = btcSnacks_;
        ethSnacks = ethSnacks_;
        pancakeSwapPool = pancakeSwapPool_;
        snacksPool = snacksPool_;
        seniorage = seniorage_;
        _grantRole(AUTHORITY_ROLE, authority_);
        if (IERC20(cakeLP_).allowance(address(this), pancakeSwapPool_) == 0) {
            IERC20(cakeLP_).approve(pancakeSwapPool_, type(uint256).max);
        }
        if (IERC20(zoinks_).allowance(address(this), snacks_) == 0) {
            IERC20(zoinks_).approve(snacks_, type(uint256).max);
        }
        if (IERC20(zoinks_).allowance(address(this), router) == 0) {
            IERC20(zoinks_).approve(router, type(uint256).max);
        }
        if (IERC20(snacks_).allowance(address(this), snacksPool_) == 0) {
            IERC20(snacks_).approve(snacksPool_, type(uint256).max);
        }
    }

    /**
    * @notice Transfers all CAKE-LP tokens on the contract to the `receiver_` address.
    * @dev Could be called only by the owner.
    * @param receiver_ Receiver address.
    */
    function withdrawCakeLP(address receiver_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 cakeLPBalance = IERC20(cakeLP).balanceOf(address(this));
        if (cakeLPBalance != 0) {
            IERC20(cakeLP).safeTransfer(receiver_, cakeLPBalance);
        }
    }

    /**
    * @notice Transfers deposited CAKE-LP tokens in the PancakeSwapPool contract to the `receiver_` address.
    * @dev Could be called only by the owner. Fees goes to the Seniorage contract.
    * @param receiver_ Receiver address.
    */
    function withdrawCakeLPFromPool(address receiver_, uint256 amount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            amount_ <= IMultipleRewardPool(pancakeSwapPool).getBalance(address(this)) &&
            amount_ != 0,
            "Pulse: invalid amount to withdraw"
        );
        uint256 cakeLPBalanceBefore = IERC20(cakeLP).balanceOf(address(this));
        IMultipleRewardPool(pancakeSwapPool).withdraw(amount_);
        IERC20(cakeLP).safeTransfer(receiver_, IERC20(cakeLP).balanceOf(address(this)) - cakeLPBalanceBefore);
    }

    /**
    * @notice Distributes BtcSnacks and EthSnacks tokens.
    * @dev Called by the authorised address once every 12 hours.
    */
    function distributeBtcSnacksAndEthSnacks() external whenNotPaused onlyRole(AUTHORITY_ROLE) {
        uint256 btcSnacksBalance = IERC20(btcSnacks).balanceOf(address(this));
        uint256 ethSnacksBalance = IERC20(ethSnacks).balanceOf(address(this));
        if (btcSnacksBalance != 0) {
            IERC20(btcSnacks).safeTransfer(
                seniorage,
                btcSnacksBalance * BTC_SNACKS_SENIORAGE_PERCENT / BASE_PERCENT
            );
        }
        if (ethSnacksBalance != 0) {
            IERC20(ethSnacks).safeTransfer(
                seniorage,
                ethSnacksBalance * ETH_SNACKS_SENIORAGE_PERCENT / BASE_PERCENT
            );
        }
    }

    /**
    * @notice Distributes Snacks tokens.
    * @dev Called by the authorised address once every 12 hours.
    */
    function distributeSnacks() external whenNotPaused onlyRole(AUTHORITY_ROLE) {
        uint256 balance = IERC20(snacks).balanceOf(address(this));
        if (balance != 0) {
            uint256 amountToDistribute = balance * SNACKS_DISTRIBUTION_PERCENT / BASE_PERCENT;
            if (ISnacksBase(snacks).sufficientBuyTokenAmountOnRedeem(amountToDistribute)) {
                // Return value is ignored.
                ISnacksBase(snacks).redeem(amountToDistribute);
            }
            IMultipleRewardPool(snacksPool).stake(amountToDistribute);
        }
    }

    /**
    * @notice Distributes Zoinks and Pancake LPs tokens.
    * @dev Called by the authorised address once every 12 hours.
    */
    function distributeZoinks() external whenNotPaused onlyRole(AUTHORITY_ROLE) {
        uint256 zoinksBalance = IERC20(zoinks).balanceOf(address(this));
        if (zoinksBalance != 0) {
            uint256 amountToDistribute = zoinksBalance * ZOINKS_DISTRIBUTION_PERCENT / BASE_PERCENT;
            if (ISnacksBase(snacks).sufficientPayTokenAmountOnMint(amountToDistribute)) {
                ISnacksBase(snacks).mintWithPayTokenAmount(amountToDistribute);
            }
        }
        uint256 cakeLPBalance = IERC20(cakeLP).balanceOf(address(this));
        if (cakeLPBalance != 0) {
            IMultipleRewardPool(pancakeSwapPool).stake(cakeLPBalance);
        }
    }

    /**
    * @notice Claims rewards from the PancakeSwapPool and SnacksPool.
    * @dev Called by the authorised address once every 12 hours.
    */
    function harvest() external whenNotPaused onlyRole(AUTHORITY_ROLE) {
        IMultipleRewardPool(pancakeSwapPool).getReward();
        IMultipleRewardPool(snacksPool).getReward();
    }
}