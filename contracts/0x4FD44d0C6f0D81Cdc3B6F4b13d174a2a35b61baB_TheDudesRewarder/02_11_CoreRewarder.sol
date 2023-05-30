//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./CoreStaking.sol";
import "./../../common/interfaces/ICoreRewarder.sol";
import "./../../common/interfaces/ICollection.sol";
import "./../../common/interfaces/IINT.sol";

contract CoreRewarder is ICoreRewarder, CoreStaking, Ownable {
    struct TokenStatus {
        uint128 lastClaimTime;
        uint128 pendingReward;
    }

    bool public isStakingEnabled;
    bool public isClaimingEnabled;

    address public immutable rewardAddress;
    uint256 public immutable rewardRate;
    uint256 public immutable rewardFrequency;
    uint256 public immutable initialReward;

    uint256 public startTime;
    uint256 public finishTime;

    mapping(uint256 => TokenStatus) public tokenStatusses;

    constructor(
        address _targetAddress,
        address _rewardAddress,
        uint256 _rewardRate,
        uint256 _rewardFrequency,
        uint256 _initialReward,
        uint256 _boostRate
    ) CoreStaking(_targetAddress, _boostRate) {
        rewardAddress = _rewardAddress;
        rewardRate = _rewardRate;
        rewardFrequency = _rewardFrequency;
        initialReward = _initialReward;
    }

    // OWNER CONTROLS

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(startTime == 0, "Start time is already set");
        startTime = _startTime;
    }

    function start() external onlyOwner {
        require(startTime == 0, "Start time is already set");
        startTime = block.timestamp;
    }

    function setFinishTime(uint256 _finishTime) external onlyOwner {
        finishTime = _finishTime;
    }

    function finish() external onlyOwner {
        finishTime = block.timestamp;
    }

    function setIsStakingEnabled(bool _isStakingEnabled) external onlyOwner {
        isStakingEnabled = _isStakingEnabled;
    }

    function setIsClaimingEnabled(bool _isClaimingEnabled) external onlyOwner {
        isClaimingEnabled = _isClaimingEnabled;
    }

    // PUBLIC - CONTROLS

    function stake(uint256[] calldata tokenIds) external override {
        require(isStakingEnabled, "Stakig is not enabled");
        if (_isRewardingStarted(startTime)) {
            _updatePendingRewards(msg.sender, tokenIds);
        }
        _stake(msg.sender, tokenIds);
    }

    function withdraw(uint256[] calldata tokenIds) external override {
        if (_isRewardingStarted(startTime)) {
            _updatePendingRewards(msg.sender, tokenIds);
        }
        _withdraw(msg.sender, tokenIds);
    }

    function claim(uint256[] calldata tokenIds) external override {
        require(isClaimingEnabled, "Claiming is not enabled");
        _claim(msg.sender, tokenIds);
    }

    function earned(uint256[] calldata tokenIds)
        external
        view
        override
        returns (uint256)
    {
        if (!_isRewardingStarted(startTime)) {
            return initialReward * tokenIds.length;
        }
        return _earnedRewards(tokenIds);
    }

    // PUBLIC - UTILITY

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _lastClaimTimesOfTokens = new uint256[](
            tokenIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _lastClaimTimesOfTokens[i] = tokenStatusses[tokenIds[i]]
                .lastClaimTime;
        }
        return _lastClaimTimesOfTokens;
    }

    function isOwner(address owner, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isOwner(owner, tokenId);
    }

    function stakedTokensOfOwner(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _stakedTokensOfOwner[owner];
    }

    function tokensOfOwner(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = ICollection(targetAddress).tokensOfOwner(
            owner
        );
        uint256[] memory stakedTokensIds = _stakedTokensOfOwner[owner];
        uint256[] memory mergedTokenIds = new uint256[](
            tokenIds.length + stakedTokensIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mergedTokenIds[i] = tokenIds[i];
        }
        for (uint256 i = 0; i < stakedTokensIds.length; i++) {
            mergedTokenIds[i + tokenIds.length] = stakedTokensIds[i];
        }
        return mergedTokenIds;
    }

    // INTERNAL

    function _claim(address _owner, uint256[] memory _tokenIds) internal {
        uint256 rewardAmount = _earnedRewards(_tokenIds);
        _resetPendingRewards(_owner, _tokenIds);

        require(rewardAmount != 0, "Can't claim 0 rewards");

        emit RewardClaimed(_owner, rewardAmount);
        IINT(rewardAddress).mint(_owner, rewardAmount);
    }

    function _updatePendingRewards(address _owner, uint256[] memory _tokenIds)
        internal
    {
        uint256 _startTime = startTime;
        uint256 _currentTime = _fixedCurrentTime();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isOwner(_owner, _tokenIds[i]),
                "You need to own this token"
            );

            TokenStatus memory status = tokenStatusses[_tokenIds[i]];
            status.pendingReward += uint128(
                _earnedTokenReward(_tokenIds[i], _startTime, _currentTime)
            );
            status.lastClaimTime = uint128(_currentTime);
            tokenStatusses[_tokenIds[i]] = status;
        }
    }

    function _resetPendingRewards(address _owner, uint256[] memory _tokenIds)
        internal
    {
        uint256 _currentTime = _fixedCurrentTime();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isOwner(_owner, _tokenIds[i]),
                "You need to own this token"
            );

            TokenStatus memory status = tokenStatusses[_tokenIds[i]];
            status.pendingReward = 0;
            status.lastClaimTime = uint128(_currentTime);
            tokenStatusses[_tokenIds[i]] = status;
        }
    }

    function _earnedRewards(uint256[] memory _tokenIds)
        internal
        view
        returns (uint256)
    {
        uint256 _startTime = startTime;
        uint256 _currentTime = _fixedCurrentTime();
        uint256 rewardAmount;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            rewardAmount += _earnedTokenReward(
                _tokenIds[i],
                _startTime,
                _currentTime
            );
            rewardAmount += tokenStatusses[_tokenIds[i]].pendingReward;
        }
        return rewardAmount;
    }

    function _earnedTokenReward(
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _currentTime
    ) internal view returns (uint256) {
        uint256 _lastClaimTimeOfToken = tokenStatusses[_tokenId].lastClaimTime;
        uint256 fixedLastClaimTimeOfToken = _fixedLastClaimTimeOfToken(
            _startTime,
            _lastClaimTimeOfToken
        );

        uint256 multiplier = _stakingMultiplierForToken(_tokenId);
        uint256 amount = ((_currentTime - fixedLastClaimTimeOfToken) /
            rewardFrequency) *
            rewardRate *
            multiplier *
            1e18;

        if (_lastClaimTimeOfToken == 0) {
            return amount + initialReward;
        }

        return amount;
    }

    function _isRewardingStarted(uint256 _startTime)
        internal
        view
        returns (bool)
    {
        if (_startTime != 0 && _startTime < block.timestamp) {
            return true;
        }
        return false;
    }

    function _fixedLastClaimTimeOfToken(
        uint256 _startTime,
        uint256 _lastClaimTimeOfToken
    ) internal pure returns (uint256) {
        if (_startTime > _lastClaimTimeOfToken) {
            return _startTime;
        }
        return _lastClaimTimeOfToken;
    }

    function _fixedCurrentTime() internal view returns (uint256) {
        uint256 period = (block.timestamp - startTime) / rewardFrequency;
        uint256 currentTime = startTime + rewardFrequency * period;
        if (finishTime != 0 && finishTime < currentTime) {
            return finishTime;
        }
        return currentTime;
    }

    function _isOwner(address _owner, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        if (stakedTokenOwners[_tokenId] == _owner) {
            return true;
        }
        return IERC721(targetAddress).ownerOf(_tokenId) == _owner;
    }

    // EVENTS
    event RewardClaimed(address indexed user, uint256 reward);
}