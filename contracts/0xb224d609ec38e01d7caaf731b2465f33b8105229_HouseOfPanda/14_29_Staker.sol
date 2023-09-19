pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This contract is a part of the House of Panda project.
 *
 * House of Panda is an NFT-based real estate investment platform that gives you access to high-yield, short-term loans.
 * This contract is built with BlackRoof engine.
 *
 */

import "ERC1155.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";

import "ERC1155Tradable.sol";
import "ICoin.sol";
import "IProjectMan.sol";
import "ProjectInfo.sol";
import "HoldingInfo.sol";
import "StakeInfo.sol";
import "SigVerifier.sol";
import "HasAdmin.sol";

uint16 constant REWARD_TYPE_HOLDING = 1;
uint16 constant REWARD_TYPE_STAKING = 2;

interface IStaker {
    function setProjectMan(address _projectMan) external;

    function getHoldingInfo(
        address user,
        uint32 projectId
    ) external view returns (HoldingInfo memory);

    function getHoldingInfoRaw(
        address user,
        uint32 projectId
    ) external view returns (HoldingInfo memory);

    function setHoldingInfoData(
        address user,
        uint32 projectId,
        HoldingInfo memory holding
    ) external;

    function getStakingInfo(
        address _staker,
        uint32 projectId
    ) external view returns (StakeInfo memory);

    function getStakingInfoRaw(
        address user,
        uint32 projectId
    ) external view returns (StakeInfo memory);

    function calculateRewards(
        uint256 _amount,
        uint64 _startTime,
        uint64 _endTime,
        uint256 apy
    ) external pure returns (uint256 rewards);

    function collectRewards(uint32 projectId) external returns (bool);

    function pause(bool _paused) external;

    function owner() external view returns (address);
}

contract Staker is ReentrancyGuard, Ownable, HasAdmin, SigVerifier {
    using SafeERC20 for ICoin;

    IProjectMan internal projectMan;
    ICoin internal stableCoin;

    bool public paused = false;

    event StakeEvent(address indexed staker, uint256 amount);
    event CollectRewards(
        address indexed staker,
        uint32 indexed projectId,
        uint256 amount
    );
    event BalanceDeposit(address indexed who, uint256 indexed amount);
    event BalanceWithdraw(address indexed who, uint256 indexed amount);

    // user -> projectId -> StakeInfo
    mapping(address => mapping(uint32 => StakeInfo)) internal stakers;
    mapping(uint64 => uint8) internal usedNonce_;
    mapping(address => mapping(uint32 => HoldingInfo)) internal holdings;

    constructor(address _stableCoin, address _admin) {
        stableCoin = ICoin(_stableCoin);
        _setAdmin(_admin);

        // approve owner
        stableCoin.safeIncreaseAllowance(address(this), type(uint256).max);
    }

    modifier onlyProjectMan() {
        require(msg.sender == address(projectMan), "!projectMan");
        _;
    }

    function setProjectMan(address _projectMan) external {
        require(projectMan == IProjectMan(address(0)), "pm set");
        require(tx.origin == owner(), "!owner");
        projectMan = IProjectMan(_projectMan);
        stableCoin.safeIncreaseAllowance(_projectMan, type(uint256).max);
    }

    function _getProject(
        uint32 projectId
    ) internal view returns (ProjectInfo memory) {
        return projectMan.getProject(projectId);
    }

    function changeAdmin(address newAdmin_) external onlyOwner {
        _setAdmin(newAdmin_);
    }

    /**
     * @dev function to calculate rewards,
     *      rewards is progressive to 12% per year.
     * @param _amount amount of stable coin.
     * @param _startTime time when staking started.
     * @param _endTime time when staking ended.
     * @return rewards amount of rewards
     */
    function calculateRewards(
        uint256 _amount,
        uint64 _startTime,
        uint64 _endTime,
        uint256 apy
    ) public pure returns (uint256 rewards) {
        uint32 a_days = uint32((_endTime - _startTime) / 1 days);
        uint256 a_amount = (_amount * apy);
        rewards = (a_amount * a_days) / 365;
        return rewards / 100;
    }

    function stake(uint32 projectId, uint32 qty) external returns (bool) {
        require(!paused, "paused");
        require(qty > 0, "!qty");

        address _sender = msg.sender;

        ProjectInfo memory project = _getProject(projectId);

        _checkProject(project);
        require(project.status == ACTIVE, "!active");
        require(project.startTime <= block.timestamp, "!start");
        require(project.endTime > block.timestamp, "!ended");

        // check is user has enough NFT to stake
        require(
            IERC1155(address(projectMan)).balanceOf(_sender, projectId) >= qty,
            "balance <"
        );

        // update stake info
        StakeInfo memory staker = stakers[_sender][projectId];

        HoldingInfo memory hld = holdings[_sender][project.id];

        uint256 holdingRewards = _accumHoldingRewards(_sender, project, hld);

        // claim remaining holding rewards first if any
        if (holdingRewards > 0) {
            stableCoin.safeTransfer(_sender, holdingRewards);
            emit CollectRewards(_sender, projectId, holdingRewards);
        }

        uint64 endTime = min(uint64(block.timestamp), project.endTime);

        // update accum if already staked before
        if (staker.qty > 0 && staker.startTime < endTime) {
            staker.accumRewards += calculateRewards(
                staker.qty * project.price,
                staker.startTime,
                endTime,
                project.stakedApy
            );
        }

        staker.qty += qty;
        staker.startTime = uint64(block.timestamp);

        hld.qty -= qty;

        stakers[_sender][projectId] = staker;
        holdings[_sender][project.id] = hld;

        return true;
    }

    function max(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min(uint64 a, uint64 b) internal pure returns (uint64) {
        return a <= b ? a : b;
    }

    /**
     * @dev get user stake info.
     */
    function getStakingInfo(
        address _staker,
        uint32 projectId
    ) external view returns (StakeInfo memory) {
        StakeInfo memory _stakeInfo = stakers[_staker][projectId];
        ProjectInfo memory project = _getProject(projectId);
        uint64 endTime = min(uint64(block.timestamp), project.endTime);

        if (_stakeInfo.startTime > endTime) {
            return _stakeInfo;
        }

        _stakeInfo.accumRewards += calculateRewards(
            _stakeInfo.qty * project.price,
            _stakeInfo.startTime,
            endTime,
            project.stakedApy
        );
        return _stakeInfo;
    }

    function _projectEnd(
        ProjectInfo memory project
    ) internal view returns (bool) {
        return block.timestamp >= project.startTime + ((1 days) * project.term);
    }

    function isProjectEnd(uint32 id) external view returns (bool) {
        ProjectInfo memory project = _getProject(id);
        return _projectEnd(project);
    }

    function unstake(uint32 projectId, uint32 qty) external returns (bool) {
        require(!paused, "paused");
        require(qty > 0, "!qty");

        address _sender = msg.sender;

        ProjectInfo memory project = _getProject(projectId);
        require(project.status == ACTIVE, "!active");

        StakeInfo memory _stakerInfo = stakers[_sender][projectId];

        require(_stakerInfo.qty != 0, "!staker.qty");

        // check is user has enough staked amount to unstake
        require(_stakerInfo.qty >= qty, "qty >");

        // unable to unstake until project end
        require(_projectEnd(project), "!end");

        uint64 endsTime = min(uint64(block.timestamp), project.endTime);

        if (_stakerInfo.startTime < endsTime) {
            // update accum rewards
            _stakerInfo.accumRewards += calculateRewards(
                _stakerInfo.qty * project.price,
                _stakerInfo.startTime,
                endsTime,
                project.stakedApy
            );
        }

        _stakerInfo.qty -= qty;
        _stakerInfo.startTime = uint64(block.timestamp);

        stakers[_sender][projectId] = _stakerInfo;

        // update holding's qty
        HoldingInfo memory hld = holdings[_sender][project.id];
        hld.qty += qty;
        holdings[_sender][project.id] = hld;

        return true;
    }

    /**
     * This function allows the user to collect rewards from staking and holding
     * tokens in a given project.
     * It takes in two parameters: 'projectId' and 'rewardType'. It first checks to
     * make sure staking is not paused
     * and that a valid type of reward is specified. Afterward, it checks that the
     * project status is active and then
     * collects rewards. If the reward type indicates staking rewards, it calculates
     * the rewards earned,
     * updates the stake information and starts a new stake period. Afterwards, it
     * transfers the collected rewards
     * to the user and emits the CollectRewards event.
     *
     * @param projectId The ID of the project to collect rewards from.
     * @param rewardType {uint16} The type of reward to collect. Can be
     *                   REWARD_TYPE_HOLDING, REWARD_TYPE_STAKING or both.
     * @return {bool} Boolean indicating success.
     */
    function collectRewards(
        uint32 projectId,
        uint16 rewardType
    ) external nonReentrant returns (bool) {
        require(!paused, "paused");
        require(
            (rewardType & REWARD_TYPE_HOLDING) != 0 ||
                (rewardType & REWARD_TYPE_STAKING) != 0,
            "!type"
        );

        address _sender = msg.sender;

        ProjectInfo memory project = _getProject(projectId);
        require(project.status == ACTIVE, "!active");
        require(project.startTime <= block.timestamp, "!start");

        StakeInfo memory stk = stakers[_sender][projectId];

        uint256 _collectedTotal = 0;

        if ((rewardType & REWARD_TYPE_HOLDING) != 0) {
            // collect holding rewards
            HoldingInfo memory _holding = holdings[_sender][project.id];
            _collectedTotal = _accumHoldingRewards(_sender, project, _holding);
        }

        if ((rewardType & REWARD_TYPE_STAKING) != 0) {
            require(stk.qty > 0, "!staked");

            // if staked, then claim for staked rewards
            // update accum rewards
            uint64 endTime = min(uint64(block.timestamp), project.endTime);

            if (stk.startTime > endTime) {
                return false;
            }

            uint256 _accumRewards = stk.accumRewards;
            _accumRewards = calculateRewards(
                stk.qty * project.price,
                stk.startTime,
                endTime,
                project.stakedApy
            );

            stk.startTime = uint64(block.timestamp);
            stk.accumRewards = 0;
            stk.claimedRewards += _accumRewards;

            stakers[_sender][projectId] = stk;

            holdings[_sender][projectId].startTime = stk.startTime;

            _collectedTotal += _accumRewards;
        }

        // transfer rewards to user
        if (_collectedTotal > 0) {
            stableCoin.safeTransfer(_sender, _collectedTotal);
            emit CollectRewards(_sender, projectId, _collectedTotal);
            return true;
        }
        // stableCoin.safeTransfer(_sender, _accumRewards);

        return false;
    }

    /**
     * This function calculates the total accumulated rewards for a given user and
     * project.
     * It takes in an '_sender' address and 'project' object.
     * It then checks if the user has any tokens in holdings and calculates the
     * rewards accordingly.
     * Finally, it updates the holding information and returns the accumulated
     * rewards.
     *
     * @param _sender The address of the user who's rewards will be calculated.
     * @param project Project object containing project info.
     * @return {uint256} The total accumulated rewards for the given user and
     * project.
     */
    function _accumHoldingRewards(
        address _sender,
        ProjectInfo memory project,
        HoldingInfo memory hld
    ) private returns (uint256) {
        if (hld.qty == 0) {
            return 0;
        }

        uint64 endTime = min(uint64(block.timestamp), project.endTime);

        if (hld.startTime > endTime) {
            return 0;
        }

        uint256 _accumRewards = hld.accumRewards;

        _accumRewards += calculateRewards(
            hld.qty * project.price,
            hld.startTime,
            endTime,
            project.apy
        );
        hld.startTime = uint64(block.timestamp);
        hld.accumRewards = 0;
        hld.claimedRewards += _accumRewards;

        holdings[_sender][project.id] = hld;

        return _accumRewards;
    }

    /**
     * @dev Function to collect specific amount of rewards from project manually,
     *      rewards is calculated off-chain and need authorization signature to proceed.
     *      This procedure can work in paused state (for emergency purpose).
     * @param projectId the ID of project.
     * @param amount the amount of rewards to collect.
     * @param nonce the nonce of the signature.
     * @param sig the signature to authorize the transaction.
     */
    function collectRewardsBy(
        uint32 projectId,
        uint256 amount,
        uint64 nonce,
        Sig memory sig
    ) external nonReentrant returns (bool) {
        require(nonce >= uint64(block.timestamp) / 60, "x nonce");
        require(usedNonce_[nonce] == 0, "x nonce");

        ProjectInfo memory project = _getProject(projectId);

        require(project.id != 0, "!project");

        address _sender = msg.sender;

        StakeInfo memory stk = stakers[_sender][projectId];

        require(stk.qty != 0, "!staker.qty");

        // check signature
        bytes32 message = sigPrefixed(
            keccak256(abi.encodePacked(projectId, _sender, amount, nonce))
        );

        require(_isSigner(admin, message, sig), "x signature");

        usedNonce_[nonce] = 1;

        uint256 _accumRewards = stk.accumRewards;

        uint64 endTime = min(uint64(block.timestamp), project.endTime);

        // if (stk.startTime > endTime) {
        //     return false;
        // }

        _accumRewards += calculateRewards(
            stk.qty * project.price,
            stk.startTime,
            endTime,
            project.stakedApy
        );

        // amount must be less or equal to accumRewards
        require(amount <= _accumRewards, "x amount");

        stk.startTime = uint64(block.timestamp);
        stk.accumRewards = _accumRewards - amount;
        stk.claimedRewards += amount;

        stakers[_sender][projectId] = stk;

        // transfer rewards to staker
        stableCoin.safeTransfer(_sender, amount);

        emit CollectRewards(_sender, projectId, amount);

        return true;
    }

    /**
     * @dev check is project exists
     */
    function _checkProject(ProjectInfo memory project) internal pure {
        require(project.id > 0, "!project");
    }

    /**
     * @dev get holding information on project of user
     */
    function getHoldingInfo(
        address user,
        uint32 projectId
    ) external view returns (HoldingInfo memory) {
        HoldingInfo memory _holding = holdings[user][projectId];
        ProjectInfo memory project = _getProject(projectId);
        uint64 endTime = min(uint64(block.timestamp), project.endTime);

        if (_holding.startTime > endTime) {
            return _holding;
        }

        _holding.accumRewards += calculateRewards(
            _holding.qty * project.price,
            _holding.startTime,
            endTime,
            project.apy
        );
        return _holding;
    }

    function getHoldingInfoRaw(
        address user,
        uint32 projectId
    ) external view returns (HoldingInfo memory) {
        return holdings[user][projectId];
    }

    function setHoldingInfoData(
        address user,
        uint32 projectId,
        HoldingInfo memory holding
    ) external onlyProjectMan {
        holdings[user][projectId] = holding;
    }

    function getStakingInfoRaw(
        address user,
        uint32 projectId
    ) public view returns (StakeInfo memory) {
        StakeInfo memory staker = stakers[user][projectId];
        return staker;
    }

    function _checkAddress(address addr) private pure {
        require(addr != address(0), "x addr");
    }

    /**
     * @dev Withdraw amount of deposit from this contract to `to` address.
     *      Caller of this function must be owner.
     * @param amount to withdraw.
     * @param to address to withdraw to.
     */
    function withdrawTo(uint256 amount, address to) external onlyOwner {
        _checkAddress(to);
        require(amount > 0, "!amount");

        require(stableCoin.balanceOf(address(this)) >= amount, "balance <");

        stableCoin.safeTransferFrom(address(this), to, amount);

        emit BalanceWithdraw(to, amount);
    }

    /**
     * This function is used to pause or unpause contract.
     * Only the owner of the contract or the project manager contract can call this function.
     *
     * @param _paused A boolean indicating whether should be paused or not.
     */
    function pause(bool _paused) external {
        require(
            owner() == _msgSender() || address(projectMan) == _msgSender(),
            "!owner"
        );
        paused = _paused;
    }
}