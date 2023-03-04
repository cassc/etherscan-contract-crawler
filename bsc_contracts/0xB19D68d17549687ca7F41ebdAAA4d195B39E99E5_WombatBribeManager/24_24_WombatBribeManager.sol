// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import "../interfaces/wombat/IWombatStaking.sol";
import "../interfaces/wombat/IVeWomV2.sol";
import "../interfaces/IBribeRewardPool.sol";

import "../interfaces/pancake/IBNBZapper.sol";
import "../interfaces/IVLMGP.sol";
import "../interfaces/wombat/IWombatVoter.sol";

import "../interfaces/wombat/IWombatBribeManager.sol";
import "../interfaces/wombat/IDelegateVoteRewardPool.sol";

/// @title WombatBribeManager
/// @author Magpie Team
contract WombatBribeManager is IWombatBribeManager, Initializable, OwnableUpgradeable {

    using SafeERC20 for IERC20;

    /* ============ Structs ============ */    

    struct Pool {
        address poolAddress;
        address rewarder;
        uint256 totalVoteInVlmgp;
        string name;
        bool isActive;
    }    

    /* ============ State Variables ============ */

    IWombatVoter public voter; // Wombat voter interface
    IVeWom public veWom; // Wombat veWOM interface
    IWombatStaking public wombatStaking; // main contract interacted with Wombat
    address public vlMGP; // vlMGP address
    address public PancakeZapper; // Pancake zapper contract

    address[] public pools;
    mapping(address => Pool) public poolInfos;

    mapping(address => uint256) public override userTotalVotedInVlmgp; // unit = locked MGP
    mapping(address => mapping(address => uint256)) public userVotedForPoolInVlmgp; // unit = locked MGP

    uint256 public totalVlMgpInVote;
    uint256 public lastCastTime;

    /* ==== variable added for first upgrade === */

    address public delegatedPool;

    /* ============ Events ============ */

    event AddPool(address indexed lp, address indexed rewarder);
    event VoteReset(address indexed lp);
    event AllVoteReset();
    event VoteCasted(address indexed caster, uint256 timestamp);

    /* ============ Errors ============ */

    error PoolNotActive();
    error NotEnoughVote();
    error PancakeZapperNotSet();
    error OutOfPoolIndex();
    error LengthMismatch();

    /* ============ Constructor ============ */

    function __WombatBribeManager_init(
        IWombatVoter _voter,
        IVeWom _veWom,
        IWombatStaking _wombatStaking,
        address _vlMGP,
        address _PancakeZapper
    ) public initializer {
        __Ownable_init();
        voter = _voter;
        veWom = _veWom;
        wombatStaking = _wombatStaking;
        vlMGP = _vlMGP;
        PancakeZapper = _PancakeZapper;     
    }

    /* ============ External Getters ============ */

    function isPoolActive(address pool) external view returns (bool) {
        return poolInfos[pool].isActive;
    }

    function vewomPerLockedMgp() public view returns (uint256) {
        if (IVLMGP(vlMGP).totalLocked() == 0) return 0;
        return (totalVotes() * 1e18) / IVLMGP(vlMGP).totalLocked();
    }

    function getUserVotable(address _user) public view returns (uint256) {
        return IVLMGP(vlMGP).getUserTotalLocked(_user);
    }

    function getUserVoteForPoolsInVlmgp(address[] calldata lps, address _user)
        public
        view
        returns (uint256[] memory votes)
    {
        uint256 length = lps.length;
        votes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            votes[i] = userVotedForPoolInVlmgp[_user][lps[i]];
        }
    }

    function getPoolsLength() external view returns (uint256) {
        return pools.length;
    }

    function lpTokenLength() public view returns (uint256) {
        return voter.lpTokenLength();
    }

    function getVoteForLp(address lp) public view returns (uint256) {
        return voter.getUserVotes(address(wombatStaking), lp);
    }

    function getVoteForLps(address[] calldata lps) public view returns (uint256[] memory votes) {
        uint256 length = lps.length;
        votes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            votes[i] = getVoteForLp(lps[i]);
        }
    }

    function getVlmgpVoteForPools(address[] calldata lps)
        public
        view
        returns (uint256[] memory vlmgpVotes)
    {
        uint256 length = lps.length;
        vlmgpVotes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[lps[i]];
            vlmgpVotes[i] = pool.totalVoteInVlmgp;
        }
    }

    function usedVote() public view returns (uint256) {
        return veWom.usedVote(address(wombatStaking));
    }

    function totalVotes() public view returns (uint256) {
        return veWom.balanceOf(address(wombatStaking));
    }

    function remainingVotes() public view returns (uint256) {
        return totalVotes() - usedVote();
    }

    function previewBnbAmountForHarvest(address[] calldata _lps) external view returns (uint256) {
        (IERC20[][] memory rewardTokens, uint256[][] memory amounts) = wombatStaking.pendingBribeCallerFee(_lps);
        return IBNBZapper(PancakeZapper).previewTotalAmount(rewardTokens, amounts);
    }    

    /// @notice Returns pending bribes
    function previewBribes(
        address _lp,
        address _for
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts) {
        Pool storage pool = poolInfos[_lp];
        (rewardTokens, ) = IBribeRewardPool(pool.rewarder).rewardTokenInfos();
        amounts = IBribeRewardPool(pool.rewarder).allEarned(_for);
    }

    /* ============ External Functions ============ */

    /// @notice Vote on pools. Need to compute the delta prior to casting this.
    /// @param _deltas delta amount in vlMGP
    function vote(address[] calldata _lps, int256[] calldata _deltas) override public {
        if (_lps.length != _deltas.length)
            revert LengthMismatch();

        uint256 length = _lps.length;
        int256 totalUserVote;

        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[_lps[i]];
            if (!pool.isActive)
                revert PoolNotActive();
            int256 delta = _deltas[i];
            totalUserVote += delta;
            if (delta != 0) {
                if (delta > 0) {
                    pool.totalVoteInVlmgp += uint256(delta);
                    userVotedForPoolInVlmgp[msg.sender][pool.poolAddress] += uint256(delta);
                    IBribeRewardPool(pool.rewarder).stakeFor(msg.sender, uint256(delta));
                } else {
                    pool.totalVoteInVlmgp -= uint256(-delta);
                    userVotedForPoolInVlmgp[msg.sender][pool.poolAddress] -= uint256(-delta);
                    IBribeRewardPool(pool.rewarder).withdrawFor(msg.sender, uint256(-delta), false);
                }
            }
        }

        if (msg.sender != delegatedPool) {
            if (totalUserVote > 0) {
                userTotalVotedInVlmgp[msg.sender] += uint256(totalUserVote);
                totalVlMgpInVote += uint256(totalUserVote);
            } else {
                userTotalVotedInVlmgp[msg.sender] -= uint256(-totalUserVote);
                totalVlMgpInVote -= uint256(-totalUserVote);
            }
        }

        if (userTotalVotedInVlmgp[msg.sender] > getUserVotable(msg.sender))
            revert NotEnoughVote();
    }

    /// @notice Unvote from an inactive pool. This makes it so that deleting a pool, or changing a rewarder doesn't block users from withdrawing
    function unvote(address _lp) public {
        Pool storage pool = poolInfos[_lp];
        uint256 currentVote = userVotedForPoolInVlmgp[msg.sender][pool.poolAddress];
        if(!pool.isActive)
            revert PoolNotActive();
        
        pool.totalVoteInVlmgp -= uint256(currentVote);
        userTotalVotedInVlmgp[msg.sender] -= uint256(currentVote);
        userVotedForPoolInVlmgp[msg.sender][pool.poolAddress] = 0;
        if (msg.sender != delegatedPool) {
            totalVlMgpInVote -= currentVote;
        }
        
        IBribeRewardPool(pool.rewarder).withdrawFor(msg.sender, uint256(currentVote), true);
    }

    /// @notice cast all pending votes
    /// @notice this  function will be gas intensive, hence a fee is given to the caller
    function castVotes(bool swapForBnb)
        override public
        returns (address[][] memory finalRewardTokens, uint256[][] memory finalFeeAmounts)
    {
        lastCastTime = block.timestamp;
        uint256 length = pools.length;
        address[] memory _pools = new address[](length);
        int256[] memory votes = new int256[](length);
        address[] memory rewarders = new address[](length);

        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[pools[i]];
            _pools[i] = pool.poolAddress;
            rewarders[i] = pool.rewarder;

            uint256 currentVote = getVoteForLp(pool.poolAddress);
            uint256 targetVoteInLMGP = pool.totalVoteInVlmgp;
            uint256 targetVote = 0;

            if (totalVlMgpInVote != 0) {
                targetVote = targetVoteInLMGP * totalVotes() / totalVlMgpInVote;
            }

            if (targetVote >= currentVote) {
                votes[i] = int256(targetVote - currentVote);
            } else {
                votes[i] = int256(targetVote) - int256(currentVote);
            }
        }

        (address[][] memory rewardTokens, uint256[][] memory feeAmounts) = wombatStaking.vote(
            _pools,
            votes,
            rewarders,
            msg.sender
        );

        // comment outs for now since chainlink fails sometimes
        // if (swapForBnb) {
        //     finalFeeAmounts = new uint256[][](1);
        //     finalFeeAmounts[0] = new uint256[](1);
        //     finalFeeAmounts[0][0] = _swapFeesForBnb(rewardTokens, feeAmounts);
        //     finalRewardTokens = new address[][](1);
        //     finalRewardTokens[0] = new address[](1);
        //     finalRewardTokens[0][0] = address(0);
        // } else {
            _forwardRewards(rewardTokens, feeAmounts);
            finalRewardTokens = rewardTokens;
            finalFeeAmounts = feeAmounts;
        // }

        // send rewards to the delegate pool
        if (delegatedPool != address(0)) IDelegateVoteRewardPool(delegatedPool).harvestAll();

        emit VoteCasted(msg.sender, lastCastTime);
    }

    /// @notice Cast a zero vote to harvest the bribes of selected pools
    /// @notice this  function has a lesser importance than casting votes, hence no rewards will be given to the caller.
    function harvestSinglePool(address[] calldata _lps) public {
        uint256 length = _lps.length;
        int256[] memory votes = new int256[](length);
        address[] memory rewarders = new address[](length);
        for (uint256 i; i < length; i++) {
            address lp = _lps[i];
            Pool storage pool = poolInfos[lp];
            rewarders[i] = pool.rewarder;
            votes[i] = 0;
        }
        wombatStaking.vote(_lps, votes, rewarders, address(0));
    }

    /// @notice Cast all pending votes, this also harvest bribes from Wombat and distributes them to the pool rewarder.
    /// @notice This  function will be gas intensive, hence a fee is given to the caller
    function voteAndCast(
        address[] calldata _lps,
        int256[] calldata _deltas,
        bool swapForBnb
    ) external returns (address[][] memory finalRewardTokens, uint256[][] memory finalFeeAmounts) {
        vote(_lps, _deltas);
        (finalRewardTokens, finalFeeAmounts) = castVotes(swapForBnb);
    }

    /// @notice Claim user rewards for each pool
    /// @notice If bribes weren't harvested, this might be lower than actual current value
    function claimBribe(address[] calldata lps) public {
        _claimBribeFor(lps, msg.sender);
    }

    /// @notice Claim user rewards for each pool
    /// @notice If bribes weren't harvested, this might be lower than actual current value
    function claimBribeFor(address[] calldata lps, address _for) public {
        _claimBribeFor(lps, _for);
    }

    /// @notice Harvests user rewards for each pool where he has voted
    /// @notice If bribes weren't harvested, this might be lower than actual current value
    /// @param _for user to harvest bribes for.
    function claimAllBribes(address _for)
        override public
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards)
    {
        address[] memory delegatePoolRewardTokens;
        uint256[] memory delegatePoolRewardAmounts;
        if (userVotedForPoolInVlmgp[_for][delegatedPool] > 0) {
            (delegatePoolRewardTokens, delegatePoolRewardAmounts) = IDelegateVoteRewardPool(delegatedPool)
                .getReward(_for);
        }

        uint256 length = pools.length;
        rewardTokens = new address[](length + delegatePoolRewardTokens.length);
        earnedRewards = new uint256[](length + delegatePoolRewardTokens.length);

        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[pools[i]];
            address lp = pool.poolAddress;
            address bribesContract = address(voter.infos(lp).bribe);
            if (bribesContract != address(0)) {
                rewardTokens[i] = address(IWombatBribe(bribesContract).rewardTokens()[0]);
                // skip the which pool not in voting to save gas
                if (userVotedForPoolInVlmgp[_for][lp] > 0) {
                    earnedRewards[i] = IBribeRewardPool(pool.rewarder).earned(_for, rewardTokens[i]);
                    if (earnedRewards[i] > 0) {
                        IBribeRewardPool(pool.rewarder).getReward(_for, _for);
                    }
                }
            }
        }

        uint256 delegatePoolRewardsLength = delegatePoolRewardTokens.length;
        for (uint256 i = length; i < length + delegatePoolRewardsLength; i++) {
            rewardTokens[i] = delegatePoolRewardTokens[i - length];
            earnedRewards[i] = delegatePoolRewardAmounts[i - length];
        }
    }

    /// @notice Cast all votes to Wombat, harvesting the rewards from Wombat for Magpie, and then harvesting specifically for the chosen pools.
    /// @notice this  function will be gas intensive, hence a fee is given to the caller for casting the vote.
    /// @param lps lps to harvest
    function castVotesAndClaimBribes(address[] calldata lps, bool swapForBnb) external {
        castVotes(swapForBnb);
        claimBribe(lps);
    }

    /* ============ Internal Functions ============ */

    function _forwardRewards(address[][] memory rewardTokens, uint256[][] memory feeAmounts) internal {
        uint256 bribeLength = rewardTokens.length;
        for (uint256 i; i < bribeLength; i++) {
            uint256 TokenLength = rewardTokens[i].length;
            for(uint256 j; j < TokenLength; j++) {
                if (rewardTokens[i][j] != address(0) && feeAmounts[i][j] > 0) {
                    IERC20(rewardTokens[i][j]).safeTransfer(msg.sender, feeAmounts[i][j]);
                }
            }
        }
    }

    /// @notice Harvests user rewards for each pool
    /// @notice If bribes weren't harvested, this might be lower than actual current value
    function _claimBribeFor(address[] calldata lps, address _for) internal {
        uint256 length = lps.length;
        for (uint256 i; i < length; i++) {
            IBribeRewardPool(poolInfos[lps[i]].rewarder).getReward(_for, _for);
        }
    }    

    /* ============ Admin Functions ============ */

    function setPancakeZapper(address newZapper) external onlyOwner {
        PancakeZapper = newZapper;
    }

    function addPool(
        address _lp,
        address _rewarder,
        string memory _name
    ) external onlyOwner {
        // it seems we have no way to check that the LP exists
        require(_lp != address(0), "ZERO ADDRESS");
        Pool memory pool = Pool({
            poolAddress: _lp,
            rewarder: _rewarder,
            totalVoteInVlmgp: 0,
            name: _name,
            isActive: true
        });
        if (_lp != delegatedPool) {
            pools.push(_lp); // we don't want the delegatedPool in this array
        }
        poolInfos[_lp] = pool;
        emit AddPool(_lp, _rewarder);
    }

    function removePool(uint256 _index) external onlyOwner {
        uint256 length = pools.length;
        if(_index >= length) revert OutOfPoolIndex();
        pools[_index] = pools[length - 1];
        pools.pop();
    }

    function setDelegatedPool(address _newDelegatedPool) external onlyOwner {
        delegatedPool = _newDelegatedPool;
    }

    function _swapFeesForBnb(address[][] memory rewardTokens, uint256[][] memory feeAmounts)
        internal
        returns (uint256 bnbAmount)
    {
        if(PancakeZapper == address(0)) revert PancakeZapperNotSet();
        uint256 bribeLength = rewardTokens.length;
        for (uint256 i; i < bribeLength; i++) {
            uint256 rewardLength = rewardTokens[i].length;
            for (uint256 j; j < rewardLength; j++) {
                if (rewardTokens[i][j] != address(0) && feeAmounts[i][j] > 0) {
                    _approveTokenIfNeeded(rewardTokens[i][j], PancakeZapper, feeAmounts[i][j]);
                    bnbAmount += IBNBZapper(PancakeZapper).zapInToken(
                        rewardTokens[i][j],
                        feeAmounts[i][j],
                        0,
                        msg.sender
                    );
                }
            }
        }
    }

    // Should replace with safeApprove?
    function _approveTokenIfNeeded(
        address token,
        address _to,
        uint256 _amount
    ) private {
        if (IERC20(token).allowance(address(this), _to) < _amount) {
            IERC20(token).approve(_to, type(uint256).max);
        }
    }
}