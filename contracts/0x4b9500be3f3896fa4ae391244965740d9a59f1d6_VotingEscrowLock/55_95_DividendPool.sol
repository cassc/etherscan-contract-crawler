//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../core/governance/interfaces/IVotingEscrowToken.sol";
import "../../core/governance/interfaces/IVotingEscrowLock.sol";
import "../../core/dividend/interfaces/IDividendPool.sol";
import "../../core/governance/Governed.sol";
import "../../utils/Utils.sol";

struct Distribution {
    uint256 totalDistribution;
    uint256 balance;
    mapping(uint256 => uint256) tokenPerWeek; // key is week num
    mapping(uint256 => uint256) claimStartWeekNum; // key is lock id
}

/** @title Dividend Pool */
contract DividendPool is
    IDividendPool,
    Governed,
    Initializable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Utils for address[];

    // public constants
    uint256 public constant epochUnit = 1 weeks; // default 1 epoch is 1 week

    // state variables
    address private _veVISION; // a.k.a RIGHT
    address private _veLocker;
    mapping(address => Distribution) private _distributions;
    mapping(address => bool) private _distributed;
    uint256 private _genesis;
    address[] private _distributedTokens;
    address[] private _featuredRewards;

    // events
    event NewReward(address token);
    event NewDistribution(address indexed token, uint256 amount);

    function initialize(
        address gov,
        address RIGHT,
        address[] memory _rewardTokens
    ) public initializer {
        _veVISION = RIGHT;
        _veLocker = IVotingEscrowToken(RIGHT).veLocker();
        Governed.initialize(gov);
        _genesis = (block.timestamp / epochUnit) * epochUnit;
        _featuredRewards = _rewardTokens;
    }

    // distribution

    function distribute(address _token, uint256 _amount)
        public
        override
        nonReentrant
    {
        if (!_distributed[_token]) {
            _distributed[_token] = true;
            _distributedTokens.push(_token);
            emit NewReward(_token);
        }
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 newBalance = IERC20(_token).balanceOf(address(this));
        Distribution storage distribution = _distributions[_token];
        uint256 increment = newBalance.sub(distribution.balance);
        distribution.balance = newBalance;
        distribution.totalDistribution = distribution.totalDistribution.add(
            increment
        );
        uint256 weekNum = getCurrentEpoch();
        distribution.tokenPerWeek[weekNum] = distribution.tokenPerWeek[weekNum]
            .add(increment);
        emit NewDistribution(_token, _amount);
    }

    /**
     * @notice If there's no ve token holder for that given epoch, anyone can call
     *          this function to redistribute the rewards to the closest epoch.
     */
    function redistribute(address token, uint256 epoch) public {
        require(
            epoch < getCurrentEpoch(),
            "Given epoch is still accepting rights."
        );
        uint256 timestamp = _genesis + epoch * epochUnit + 1 weeks;
        require(
            IVotingEscrowToken(_veVISION).totalSupplyAt(timestamp) == 0,
            "Locked Token exists for that epoch"
        );
        uint256 newEpoch;
        uint256 increment = 1;
        while (timestamp + (increment * 1 weeks) <= block.timestamp) {
            if (
                IVotingEscrowToken(_veVISION).totalSupplyAt(
                    timestamp + (increment * 1 weeks)
                ) > 0
            ) {
                newEpoch = epoch + increment;
                break;
            }
            increment += 1;
        }
        require(newEpoch > epoch, "Failed to find new epoch to redistribute");
        Distribution storage distribution = _distributions[token];
        distribution.tokenPerWeek[newEpoch] = distribution.tokenPerWeek[
            newEpoch
        ]
            .add(distribution.tokenPerWeek[epoch]);
        distribution.tokenPerWeek[epoch] = 0;
    }

    // claim

    function claim(address token) public nonReentrant {
        uint256 prevEpochTimestamp = block.timestamp - epochUnit; // safe from underflow
        _claimUpTo(token, prevEpochTimestamp);
    }

    function claimUpTo(address token, uint256 timestamp) public nonReentrant {
        _claimUpTo(token, timestamp);
    }

    function claimBatch(address[] memory tokens) public nonReentrant {
        uint256 prevEpochTimestamp = block.timestamp - epochUnit; // safe from underflow
        for (uint256 i = 0; i < tokens.length; i++) {
            _claimUpTo(tokens[i], prevEpochTimestamp);
        }
    }

    // governance
    function setFeaturedRewards(address[] memory featured) public governed {
        _featuredRewards = featured;
    }

    function genesis() public view override returns (uint256) {
        return _genesis;
    }

    function veVISION() public view override returns (address) {
        return _veVISION;
    }

    function veLocker() public view override returns (address) {
        return _veLocker;
    }

    function getEpoch(uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        return (timestamp - _genesis) / epochUnit; // safe from underflow
    }

    /** @notice 1 epoch is 1 week */
    function getCurrentEpoch() public view override returns (uint256) {
        return getEpoch(block.timestamp);
    }

    function distributedTokens()
        public
        view
        override
        returns (address[] memory)
    {
        return _distributedTokens;
    }

    function totalDistributed(address token)
        public
        view
        override
        returns (uint256)
    {
        return _distributions[token].totalDistribution;
    }

    function distributionBalance(address token)
        public
        view
        override
        returns (uint256)
    {
        return _distributions[token].balance;
    }

    function distributionOfWeek(address token, uint256 epochNum)
        public
        view
        override
        returns (uint256)
    {
        return _distributions[token].tokenPerWeek[epochNum];
    }

    function claimStartWeek(address token, uint256 veLockId)
        public
        view
        override
        returns (uint256)
    {
        return _distributions[token].claimStartWeekNum[veLockId];
    }

    function claimable(address token) public view override returns (uint256) {
        Distribution storage distribution = _distributions[token];
        uint256 currentEpoch = getCurrentEpoch();
        if (currentEpoch == 0) return 0;
        uint256 myLocks = IVotingEscrowLock(_veLocker).balanceOf(msg.sender);
        uint256 acc;
        for (uint256 i = 0; i < myLocks; i++) {
            uint256 lockId =
                IERC721Enumerable(_veLocker).tokenOfOwnerByIndex(msg.sender, i);
            acc = acc.add(_claimable(distribution, lockId, currentEpoch - 1));
        }
        return acc;
    }

    function featuredRewards() public view override returns (address[] memory) {
        return _featuredRewards;
    }

    function _claimUpTo(address token, uint256 timestamp) internal {
        uint256 epoch = getEpoch(timestamp);
        uint256 myLocks = IVotingEscrowLock(_veLocker).balanceOf(msg.sender);
        uint256 amountToClaim = 0;
        for (uint256 i = 0; i < myLocks; i++) {
            uint256 lockId =
                IERC721Enumerable(_veLocker).tokenOfOwnerByIndex(msg.sender, i);

            uint256 amount = _recordClaim(token, lockId, epoch);
            amountToClaim = amountToClaim.add(amount);
        }
        if (amountToClaim != 0) {
            IERC20(token).safeTransfer(msg.sender, amountToClaim);
        }
    }

    function _recordClaim(
        address token,
        uint256 tokenId,
        uint256 epoch
    ) internal returns (uint256 amountToClaim) {
        Distribution storage distribution = _distributions[token];
        amountToClaim = _claimable(distribution, tokenId, epoch);
        distribution.claimStartWeekNum[tokenId] = epoch + 1;
        distribution.balance = distribution.balance.sub(amountToClaim);
        return amountToClaim;
    }

    function _claimable(
        Distribution storage distribution,
        uint256 tokenId,
        uint256 epoch
    ) internal view returns (uint256) {
        require(epoch < getCurrentEpoch(), "Current epoch is being updated.");
        uint256 epochCursor = distribution.claimStartWeekNum[tokenId];
        uint256 endEpoch;
        {
            (, uint256 start, uint256 end) =
                IVotingEscrowLock(_veLocker).locks(tokenId);
            epochCursor = epochCursor != 0 ? epochCursor : getEpoch(start);
            endEpoch = getEpoch(end);
        }
        uint256 accumulated;
        while (epochCursor <= epoch && epochCursor <= endEpoch) {
            // check the balance when the epoch ends
            uint256 timestamp = _genesis + epochCursor * epochUnit + 1 weeks;
            // calculate amount;
            uint256 bal =
                IVotingEscrowToken(_veVISION).balanceOfLockAt(
                    tokenId,
                    timestamp
                );
            uint256 supply =
                IVotingEscrowToken(_veVISION).totalSupplyAt(timestamp);
            if (supply != 0) {
                accumulated = accumulated.add(
                    distribution.tokenPerWeek[epochCursor].mul(bal).div(supply)
                );
            }
            // update cursor
            epochCursor += 1;
        }
        return accumulated;
    }
}