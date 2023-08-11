// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IGauge} from "../../interfaces/IGauge.sol";
import {IGaugeUniswapV3} from "../../interfaces/IGaugeUniswapV3.sol";
import {IGaugeVoterV2} from "../../interfaces/IGaugeVoterV2.sol";
import {INFTStaker} from "../../interfaces/INFTStaker.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";
import {NFTPositionInfo} from "../../utils/NFTPositionInfo.sol";
import {UniswapV3Base} from "./UniswapV3Base.sol";
import {VersionedInitializable} from "../../proxy/VersionedInitializable.sol";

contract GaugeUniswapV3 is Ownable, VersionedInitializable, UniswapV3Base {
    using SafeMath for uint256;
    using SafeMath for uint128;

    address public treasury;

    // mapping to check lock duration
    mapping(uint256 => uint256) public lockDuration;
    mapping(uint256 => uint256) public unlockAt;

    function initialize(
        address _registry,
        address _token0,
        address _token1,
        uint24 _fee,
        address _nonfungiblePositionManager,
        address _treasury
    ) public initializer {
        super._initialize(
            _registry,
            _token0,
            _token1,
            _fee,
            _nonfungiblePositionManager
        );

        treasury = _treasury;
        _transferOwnership(address(0));
    }

    modifier updateReward(uint256 _tokenId) {
        _updateReward(_tokenId);
        _;
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 3;
    }

    function getLiquidityAndInRange(
        uint256 _tokenId
    )
        external
        view
        returns (IUniswapV3Pool _p, bool _inRange, uint128 liquidity)
    {
        return _getLiquidityAndInRange(_tokenId);
    }

    function _getReward(
        uint256 _tokenId
    ) internal nonReentrant updateReward(_tokenId) onlyTokenOwner(_tokenId) {
        uint256 reward = rewards[_tokenId];
        if (reward > 0) {
            rewards[_tokenId] = 0;
            IERC20(registry.maha()).transfer(_deposits[_tokenId].owner, reward);
            emit RewardPaid(_deposits[_tokenId].owner, _tokenId, reward);
        }
    }

    function _onERC721Received(
        address _from,
        uint256 _tokenId,
        uint256 _lockDuration
    ) internal {
        (
            IUniswapV3Pool _pool,
            bool inRange,
            uint128 liquidity
        ) = _getLiquidityAndInRange(_tokenId);

        require(
            address(_pool) == address(pool),
            "token pool is not the right pool"
        );
        require(inRange, "liquidty not in range");
        require(liquidity > 0, "cannot stake 0 liquidity");

        _updateReward(_tokenId);
        _increaseLockDurationTo(_tokenId, _lockDuration);

        uint256 __derivedLiquidity = _derivedLiquidity(
            _tokenId,
            liquidity,
            _from
        );

        _deposits[_tokenId] = Deposit({
            owner: _from,
            liquidity: liquidity,
            derivedLiquidity: __derivedLiquidity
        });

        _addTokenToAllTokensEnumeration(_tokenId);
        _addTokenToOwnerEnumeration(_from, _tokenId);

        balanceOf[_from] += 1;
        totalSupply = totalSupply.add(__derivedLiquidity);

        if (!attached[_from]) {
            attached[_from] = true;
            IGaugeVoterV2(registry.gaugeVoter()).attachStakerToGauge(_from);
        }

        // update rewards
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewards[_tokenId] = _earned(_tokenId);
        userRewardPerTokenPaid[_tokenId] = rewardPerTokenStored;

        emit Staked(_from, _tokenId, liquidity, __derivedLiquidity);
    }

    function _claimFees(uint256 _tokenId) internal {
        // send fees to the treasury
        nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: treasury,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function _updateLiquidity(uint256 _tokenId) private {
        (, , , uint128 _liquidity) = NFTPositionInfo.getPositionInfo(
            factory,
            nonfungiblePositionManager,
            _tokenId
        );

        if (_liquidity == _deposits[_tokenId].liquidity) return;

        address _who = _deposits[_tokenId].owner;

        // calculate new liquidty
        uint256 __derivedLiquidity = _derivedLiquidity(
            _tokenId,
            _liquidity,
            _who
        );

        // remove old, add new derived liquidity
        totalSupply = totalSupply.add(__derivedLiquidity).sub(
            _deposits[_tokenId].derivedLiquidity
        );

        // update old
        _deposits[_tokenId].liquidity = _liquidity;
        _deposits[_tokenId].derivedLiquidity = __derivedLiquidity;
    }

    function _getLiquidityAndInRange(
        uint256 _tokenId
    )
        private
        view
        returns (IUniswapV3Pool _p, bool _inRange, uint128 liquidity)
    {
        (
            IUniswapV3Pool _pool,
            int24 _tickLower,
            int24 _tickUpper,
            uint128 _liquidity
        ) = NFTPositionInfo.getPositionInfo(
                factory,
                nonfungiblePositionManager,
                _tokenId
            );

        (, int24 tick, , , , , ) = _pool.slot0();

        _p = _pool;
        _inRange = _tickLower <= tick && tick <= _tickUpper;
        liquidity = _liquidity;
    }

    function _updateReward(uint256 _tokenId) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_tokenId != 0) {
            rewards[_tokenId] = _earned(_tokenId);
            userRewardPerTokenPaid[_tokenId] = rewardPerTokenStored;
            _updateLiquidity(_tokenId);
        }
    }

    function _earned(uint256 _tokenId) internal view returns (uint256) {
        return
            _deposits[_tokenId]
                .derivedLiquidity
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_tokenId]))
                .div(1e18)
                .add(rewards[_tokenId]);
    }

    function _derivedLiquidity(
        uint256 nftId,
        uint128 liquidity,
        address account
    ) internal view returns (uint256) {
        uint256 duration = lockDuration[nftId];
        uint256 stake = INFTStaker(registry.staker()).balanceOf(account);

        // because of this we are able to max out the boost by 5x
        return derivedBalanceFor(liquidity, stake, duration);
    }

    function derivedBalanceFor(
        uint256 liquidity,
        uint256 mahax,
        uint256 duration
    ) public view returns (uint256) {
        uint256 _derived = (liquidity * 20) / 100;

        // give 50% weight to mahax boost
        uint256 mahaxBoost = (1e8 * mahax) / maxBoostRequirement;

        // give 50% weight to lock boost
        uint256 lockBoost = (1e8 * duration) / 126144000;

        // calculate the boost
        uint256 boost = (liquidity * ((mahaxBoost + lockBoost) * 40)) / 1e8;

        // because of this we are able to max out the boost by 5x
        return Math.min(_derived + boost, liquidity);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) return rewardPerTokenStored;
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply)
            );
    }

    function _withdraw(
        uint256 tokenId
    ) internal nonReentrant updateReward(tokenId) onlyTokenOwner(tokenId) {
        // claim fees for the treasury
        _claimFees(tokenId);

        require(block.timestamp > unlockAt[tokenId], "!withdraw when locked");
        require(_deposits[tokenId].liquidity > 0, "Cannot withdraw 0");
        totalSupply = totalSupply.sub(_deposits[tokenId].derivedLiquidity);
        delete _deposits[tokenId];

        // delete the nft from our array
        _removeTokenFromOwnerEnumeration(msg.sender, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);
        balanceOf[msg.sender] -= 1;

        // send the NFT back to the user
        nonfungiblePositionManager.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        // detach if empty
        if (balanceOf[msg.sender] == 0 && attached[msg.sender]) {
            attached[msg.sender] = false;
            IGaugeVoterV2(registry.gaugeVoter()).detachStakerFromGauge(
                msg.sender
            );
        }

        emit Withdrawn(msg.sender, tokenId);
    }

    function getReward(uint256 _tokenId) external override {
        _getReward(_tokenId);
    }

    function getReward(address account, address[] memory) external override {
        for (uint256 index = 0; index < balanceOf[account]; index++) {
            uint256 _tokenId = _ownedTokens[account][index];
            _getReward(_tokenId);
        }
    }

    function earned(uint256 _tokenId) external view override returns (uint256) {
        return _earned(_tokenId);
    }

    function derivedLiquidity(
        uint256 nftId,
        uint128 liquidity,
        address account
    ) external view override returns (uint256) {
        return _derivedLiquidity(nftId, liquidity, account);
    }

    function withdraw(uint256 tokenId) external override {
        _withdraw(tokenId);
    }

    function exit(uint256 _tokenId) external override {
        _withdraw(_tokenId);
        _getReward(_tokenId);
    }

    function claimFeesMultiple(uint256[] memory _tokenIds) external override {
        for (uint256 i = 0; i < _tokenIds.length; i++) _claimFees(_tokenIds[i]);
    }

    function claimFees(uint256 _tokenId) external override {
        _claimFees(_tokenId);
    }

    /// @notice Upon receiving a Uniswap V3 ERC721, creates the token deposit setting owner to `from`. Also stakes token
    /// in one or more incentives if properly formatted `data` has a length > 0.
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata params
    ) external override returns (bytes4) {
        require(
            msg.sender == address(nonfungiblePositionManager),
            "not called from nft manager"
        );

        // decode lock duration
        if (params.length > 0) {
            uint256 _lockDuration = abi.decode(params, (uint256));
            _onERC721Received(from, tokenId, _lockDuration);
        } else _onERC721Received(from, tokenId, 0);

        return this.onERC721Received.selector;
    }

    function increaseLockDurationTo(
        uint256 _tokenId,
        uint256 duration
    ) public onlyTokenOwner(_tokenId) {
        require(_deposits[_tokenId].liquidity > 0, "liquidity is 0");
        _increaseLockDurationTo(_tokenId, duration);
        _updateReward(_tokenId);
    }

    function _increaseLockDurationTo(
        uint256 _tokenId,
        uint256 duration
    ) internal {
        if (duration == lockDuration[_tokenId]) return;
        if (unlockAt[_tokenId] == 0) unlockAt[_tokenId] = block.timestamp;

        require(duration > lockDuration[_tokenId], "duration too short");
        require(
            duration <= 86400 * 365 * 4, // max 4 years
            "duration too long"
        );

        // capture lock duration
        unlockAt[_tokenId] =
            unlockAt[_tokenId] +
            duration -
            lockDuration[_tokenId];
        lockDuration[_tokenId] = duration;
    }

    function notifyRewardAmount(
        address,
        uint256 reward
    ) external override updateReward(0) {
        require(msg.sender == registry.gaugeVoter(), "not gauge voter");

        // fetch rewards from voter
        IERC20 maha = IERC20(registry.maha());
        maha.transferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= periodFinish)
            rewardRate = reward.div(rewardsDuration);
        else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(registry.maha()).balanceOf(address(this));

        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function updateRewardFor(uint256 _tokenId) external override {
        require(_deposits[_tokenId].liquidity > 0, "liquidity is 0");
        _updateReward(_tokenId);
    }

    function isIdsWithinRange(
        uint256[] memory tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory ret = new bool[](tokenIds.length);

        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            (
                IUniswapV3Pool _pool,
                int24 tickLower,
                int24 tickUpper,

            ) = NFTPositionInfo.getPositionInfo(
                    factory,
                    nonfungiblePositionManager,
                    tokenId
                );

            (, int24 tick, , , , , ) = _pool.slot0();
            ret[index] = _pool == pool && tickLower < tick && tick < tickUpper;
        }

        return ret;
    }

    function boostedFactor(
        uint256 _tokenId,
        address _from
    )
        external
        view
        returns (uint256 original, uint256 boosted, uint256 factor)
    {
        (, , , uint128 _liquidity) = NFTPositionInfo.getPositionInfo(
            factory,
            nonfungiblePositionManager,
            _tokenId
        );

        original = (_liquidity * 20) / 100;
        boosted = _derivedLiquidity(_tokenId, _liquidity, _from);
        factor = (boosted * 1e18) / original;
    }
}