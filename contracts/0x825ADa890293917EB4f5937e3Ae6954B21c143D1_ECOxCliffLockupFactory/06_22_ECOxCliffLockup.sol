pragma solidity 0.8.15;

import {ECOxChunkedLockup} from "./ECOxChunkedLockup.sol";
import {IECOx} from "./interfaces/IECOx.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {ChunkedVestingVault} from "vesting/ChunkedVestingVault.sol";
import {IECOxStaking} from "./interfaces/IECOxStaking.sol";

/**
 * @notice ECOxCliffLockup contract is funded regularly with ECOx. Until a cliff date has passed,
 * the funds cannot be removed, but otherwise there is no unlock schedule and payout is determined by
 * the funding schedule instead. It is initialized with only one timestamp (cliff date) and an initial
 * token amount of zero. The methods found in ChunkedVestingVaultArgs will not provide useful information
 * and any methods referring to amounts, instead the vault is intended to be emptyable at will by the
 * beneficiary after the cliff date.
 *
 * Due to the vault being funded multiple times over its lifetime, primary delegation must be used.
 */
contract ECOxCliffLockup is ECOxChunkedLockup {
    function initialize(address admin, address staking)
        public
        override
        initializer
    {
        ChunkedVestingVault._initialize(admin);

        address _stakedToken = staking;
        if (_stakedToken == address(0)) revert InvalidLockup();
        stakedToken = _stakedToken;
    }

    /**
     * @notice calculates tokens vested at a given timestamp
     * @param timestamp The time for which vested tokens are being calculated
     * @return amount of tokens vested at timestamp
     */
    function vestedOn(uint256 timestamp)
        public
        view
        override
        returns (uint256 amount)
    {
        return
            timestamp >= this.timestampAtIndex(0)
                ? token().balanceOf(address(this)) +
                    IERC20Upgradeable(stakedToken).balanceOf(address(this))
                : 0;
    }

    /**
     * @notice Delegates staked ECOx to a chosen recipient
     * @param who The address to delegate to
     */
    function _delegate(address who) internal override {
        IECOxStaking(stakedToken).delegate(who);
        currentDelegate = who;
    }

    /**
     * @notice helper function unstaking required tokens before they are claimed
     * @param amount amount of vested tokens being claimed
     */
    function onClaim(uint256 amount) internal override {
        uint256 balance = token().balanceOf(address(this));
        if (balance < amount) {
            _unstake(amount - balance);
        }
    }
}