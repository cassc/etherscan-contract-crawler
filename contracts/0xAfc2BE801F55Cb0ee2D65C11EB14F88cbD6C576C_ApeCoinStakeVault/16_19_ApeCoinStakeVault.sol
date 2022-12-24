// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interface/IApeCoinStakeVault.sol";
import "./Interface/IApeCoinStaking.sol";
import "./ERC4626.sol";

/**
 * @dev The contract provides auto compounded staking mechanism for
 * $ape coin staking.
 * It implements ERC4626 "Tokenized Vault Standard" to manage
 * the shares and yield of the users.
 */
contract ApeCoinStakeVault is ERC4626, IApeCoinStakeVault, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MIN_DEPOSIT = 1e18;
    uint256 public constant APECOIN_POOL_ID = 0;
    uint256 public constant APECOIN_TOKEN_ID = 0;

    IApeCoinStaking public immutable staking;
    uint256 public constant FEE_CAP = 1000; // 10% hard cap on fee
    uint256 public FEE;

    /* ===== INIT ===== */
    /**
     * @dev Set the $Ape coin address, staking contract address and
     * admin fees for the protocol.
     * NOTE Admin fees must be in basis points and should not exceed 10000 by definition
     */
    constructor(
        address _apeCoin,
        address _staking,
        uint256 _fees
    ) ERC4626(ERC20(_apeCoin), "X Ape", "xAPE") {
        require(_fees <= FEE_CAP, "Invalid fee value");
        FEE = _fees;
        staking = IApeCoinStaking(_staking);
        _asset.approve(_staking, type(uint256).max);
    }

    /** @dev See {IApeCoinStakeVault - harvest}. */
    function harvestYield() public override {
        // calculate accumilated fees
        uint256 pending = staking.pendingRewards(
            APECOIN_POOL_ID,
            address(this),
            APECOIN_TOKEN_ID
        );

        uint256 fees = (pending * FEE) / 10000;

        // claim $ape rewards
        staking.claimSelfApeCoin();

        // transfer fees to admin
        _asset.safeTransfer(owner(), fees);

        // deposit if amount is > MIN_DEPOSIT
        if (_asset.balanceOf(address(this)) > MIN_DEPOSIT) {
            staking.depositSelfApeCoin(_asset.balanceOf(address(this)));
        }
        emit Harvested(pending, fees);
    }

    /** @dev See {IApeCoinStakeVault - setFee}. */
    function setFee(uint256 _fees) external onlyOwner {
        require(_fees <= FEE_CAP, "Invalid fee value");
        FEE = _fees;
    }

    /** @dev See {ERC4626 - _afterDeposit}. */
    function _afterDepositHook() internal override {
        // harvest the yield
        harvestYield();
    }

    /** @dev See {ERC4626 - _beforeWithdraw}. */
    function _beforeWithdrawHook(uint256 assets) internal override {
        // harvest the yield
        harvestYield();

        // unstake the withdrawing amount
        staking.withdrawSelfApeCoin(assets);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view override returns (uint256) {
        // get self balance
        uint256 currentBalance = _asset.balanceOf(address(this));

        // get current yeild
        uint256 pendingRewards = staking.pendingRewards(
            APECOIN_POOL_ID,
            address(this),
            APECOIN_TOKEN_ID
        );

        // get total pricipal staked
        uint256 totalStaked = staking.stakedTotal(address(this));

        uint256 adminFees = (pendingRewards * FEE) / 10000;
        return currentBalance + totalStaked + pendingRewards - adminFees;
    }
}