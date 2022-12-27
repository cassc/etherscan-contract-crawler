// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@prb/math/contracts/PRBMathUD60x18.sol";

import "./base/SnacksBase.sol";
import "./interfaces/ISnacks.sol";

contract BtcSnacks is SnacksBase {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using PRBMathUD60x18 for uint256;
    
    uint256 private constant STEP = 0.00000001 * 1e18;
    uint256 private constant CORRELATION_FACTOR = 1e26;
    uint256 private constant TOTAL_SUPPLY_FACTOR = 1e8;
    uint256 private constant PULSE_FEE_PERCENT = 1500;
    uint256 private constant POOL_REWARD_DISTRIBUTOR_FEE_PERCENT = 3500;
    uint256 private constant SENIORAGE_FEE_PERCENT = 1500;
    uint256 private constant SNACKS_FEE_PERCENT = 1500;

    address public snacks;

    constructor()
        SnacksBase(
            STEP,
            CORRELATION_FACTOR,
            TOTAL_SUPPLY_FACTOR,
            PULSE_FEE_PERCENT,
            POOL_REWARD_DISTRIBUTOR_FEE_PERCENT,
            SENIORAGE_FEE_PERCENT,
            "btcSnacks",
            "BSNACK"
        )
    {}
    
    /** 
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param btc_ Binance-Peg BTCB token address.
    * @param pulse_ Pulse contract address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    * @param snacksPool_ SnacksPool contract address.
    * @param pancakeSwapPool_ PancakeSwapPool contract address.
    * @param lunchBox_ LunchBox contract address.
    * @param authority_ Authorised address.
    * @param snacks_ Snacks token address.
    */
    function configure(
        address btc_,
        address pulse_,
        address poolRewardDistributor_,
        address seniorage_,
        address snacksPool_,
        address pancakeSwapPool_,
        address lunchBox_,
        address authority_,
        address snacks_
    )
        external
        onlyOwner
    {
        _configure(
            btc_,
            pulse_,
            poolRewardDistributor_,
            seniorage_,
            snacksPool_,
            pancakeSwapPool_,
            lunchBox_,
            authority_
        );
        snacks = snacks_;
        _excludedHolders.add(snacks_);
    }
    
    /** 
    * @notice Hook that is called inside `distributeFee()` function.
    * @dev Shouldn't be used without overriden logic.
    * @param undistributedFee_ Amount of the undistributed fee.
    */
    function _beforeDistributeFee(
        uint256 undistributedFee_
    )
        internal
        override
    {
        uint256 feeAmount = undistributedFee_ * SNACKS_FEE_PERCENT / BASE_PERCENT;
        if (feeAmount != 0) {
            IERC20(address(this)).safeTransfer(snacks, feeAmount);
        }
        ISnacks(snacks).notifyBtcSnacksFeeAmount(feeAmount);
    }
}