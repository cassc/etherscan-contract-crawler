// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableFoundation.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/RewardPool.sol";
import "contracts/Lockup.sol";

/**
 * @notice This contract holds all ALCA that is held in escrow for lockup
 * bonuses. All ALCA is hold into a single staked position that is owned
 * locally.
 * @dev deployed by the RewardPool contract
 */
contract BonusPool is
    ImmutableALCA,
    ImmutablePublicStaking,
    ImmutableFoundation,
    ERC20SafeTransfer,
    EthSafeTransfer,
    ERC721Holder,
    AccessControlled,
    MagicEthTransfer
{
    uint256 internal immutable _totalBonusAmount;
    address internal immutable _lockupContract;
    address internal immutable _rewardPool;
    // tokenID of the position created to hold the amount that will be redistributed as bonus
    uint256 internal _tokenID;

    event BonusPositionCreated(uint256 tokenID);

    constructor(
        address aliceNetFactory_,
        address lockupContract_,
        address rewardPool_,
        uint256 totalBonusAmount_
    )
        ImmutableFactory(aliceNetFactory_)
        ImmutableALCA()
        ImmutablePublicStaking()
        ImmutableFoundation()
    {
        _totalBonusAmount = totalBonusAmount_;
        _lockupContract = lockupContract_;
        _rewardPool = rewardPool_;
    }

    receive() external payable {
        if (msg.sender != _publicStakingAddress()) {
            revert LockupErrors.AddressNotAllowedToSendEther();
        }
    }

    /// @notice function that creates/mint a publicStaking position with an amount that will be
    /// redistributed as bonus at the end of the lockup period. The amount of ALCA has to be
    /// transferred before calling this function.
    /// @dev can be only called by the AliceNet factory
    function createBonusStakedPosition() public onlyFactory {
        if (_tokenID != 0) {
            revert LockupErrors.BonusTokenAlreadyCreated();
        }
        IERC20 alca = IERC20(_alcaAddress());
        //get the total balance of ALCA owned by bonus pool as stake amount
        uint256 _stakeAmount = alca.balanceOf(address(this));
        if (_stakeAmount < _totalBonusAmount) {
            revert LockupErrors.NotEnoughALCAToStake(_stakeAmount, _totalBonusAmount);
        }
        // approve the staking contract to transfer the ALCA
        alca.approve(_publicStakingAddress(), _totalBonusAmount);
        uint256 tokenID = IStakingNFT(_publicStakingAddress()).mint(_totalBonusAmount);
        _tokenID = tokenID;
        emit BonusPositionCreated(_tokenID);
    }

    /// @notice Burns that bonus staked position, and send the bonus amount of shares + profits to
    /// the rewardPool contract, so users can collect.
    function terminate() public onlyLockup {
        if (_tokenID == 0) {
            revert LockupErrors.BonusTokenNotCreated();
        }
        // burn the nft to collect all profits.
        IStakingNFT(_publicStakingAddress()).burn(_tokenID);
        // restarting the _tokenID
        _tokenID = 0;
        // send the total balance of ALCA to the rewardPool contract
        uint256 alcaBalance = IERC20(_alcaAddress()).balanceOf(address(this));
        _safeTransferERC20(
            IERC20Transferable(_alcaAddress()),
            _getRewardPoolAddress(),
            alcaBalance
        );
        // send also all the balance of ether
        uint256 ethBalance = address(this).balance;
        RewardPool(_getRewardPoolAddress()).deposit{value: ethBalance}(alcaBalance);
    }

    /// @notice gets the lockup contract address
    /// @return the lockup contract address
    function getLockupContractAddress() public view returns (address) {
        return _getLockupContractAddress();
    }

    /// @notice gets the rewardPool contract address
    /// @return the rewardPool contract address
    function getRewardPoolAddress() public view returns (address) {
        return _getRewardPoolAddress();
    }

    /// @notice gets the tokenID of the publicStaking position that has the whole bonus amount
    /// @return the tokenID of the publicStaking position that has the whole bonus amount
    function getBonusStakedPosition() public view returns (uint256) {
        return _tokenID;
    }

    /// @notice gets the total amount of ALCA that was staked initially in the publicStaking position
    /// @return the total amount of ALCA that was staked initially in the publicStaking position
    function getTotalBonusAmount() public view returns (uint256) {
        return _totalBonusAmount;
    }

    /// @notice estimates a user's bonus amount + bonus position profits.
    /// @param currentSharesLocked_ The current number of shares locked in the lockup contract
    /// @param userShares_ The amount of shares that a user locked-up.
    /// @return bonusRewardEth the estimated amount ether profits for a user
    /// @return bonusRewardToken the estimated amount ALCA profits for a user
    function estimateBonusAmountWithReward(
        uint256 currentSharesLocked_,
        uint256 userShares_
    ) public view returns (uint256 bonusRewardEth, uint256 bonusRewardToken) {
        if (_tokenID == 0) {
            return (0, 0);
        }

        (uint256 estimatedPayoutEth, uint256 estimatedPayoutToken) = IStakingNFT(
            _publicStakingAddress()
        ).estimateAllProfits(_tokenID);

        (uint256 shares, , , , ) = IStakingNFT(_publicStakingAddress()).getPosition(_tokenID);
        estimatedPayoutToken += shares;

        // compute what will be the amount that a user will receive from the amount that will be
        // sent to the reward contract.
        bonusRewardEth = (estimatedPayoutEth * userShares_) / currentSharesLocked_;
        bonusRewardToken = (estimatedPayoutToken * userShares_) / currentSharesLocked_;
    }

    function _getLockupContractAddress() internal view override returns (address) {
        return _lockupContract;
    }

    function _getBonusPoolAddress() internal view override returns (address) {
        return address(this);
    }

    function _getRewardPoolAddress() internal view override returns (address) {
        return _rewardPool;
    }
}