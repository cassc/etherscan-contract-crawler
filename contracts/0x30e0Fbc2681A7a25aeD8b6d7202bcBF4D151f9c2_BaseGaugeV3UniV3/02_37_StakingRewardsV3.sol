// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {NFTPositionInfo} from "../../utils/NFTPositionInfo.sol";
import {IGaugeVoterV2} from "../../interfaces/IGaugeVoterV2.sol";
import {IGauge} from "../../interfaces/IGauge.sol";
import {UniswapV3Base} from "./UniswapV3Base.sol";
import {INFTStaker} from "../../interfaces/INFTStaker.sol";

abstract contract StakingRewardsV3 is UniswapV3Base {
    using SafeMath for uint256;
    using SafeMath for uint128;

    function derivedLiquidity(uint128 _liquidity, address account)
        public
        view
        returns (uint128)
    {
        uint128 _derived = (_liquidity * 20) / 100;
        uint256 stake = INFTStaker(registry.staker()).balanceOf(account);

        uint128 _adjusted = ((_liquidity * uint128(stake) * 80) /
            uint128(maxBoostRequirement)) / 100;

        // because of this we are able to max out the boost by 5x
        return
            _derived + _adjusted < _liquidity
                ? _derived + _adjusted
                : _liquidity;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function withdraw(uint256 tokenId)
        public
        nonReentrant
        updateReward(tokenId)
        onlyTokenOwner(tokenId)
    {
        require(deposits[tokenId].liquidity > 0, "Cannot withdraw 0");

        totalSupply = totalSupply.sub(deposits[tokenId].derivedLiquidity);
        delete deposits[tokenId];

        // delete the nft from our array
        _removeTokenFromOwnerEnumeration(msg.sender, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);
        balanceOf[msg.sender] -= 1;

        nonfungiblePositionManager.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        if (balanceOf[msg.sender] == 0 && attached[msg.sender]) {
            attached[msg.sender] = false;
            IGaugeVoterV2(registry.gaugeVoter()).detachStakerFromGauge(
                msg.sender
            );
        }

        emit Withdrawn(msg.sender, tokenId);
    }

    function getReward(uint256 _tokenId)
        public
        nonReentrant
        updateReward(_tokenId)
        onlyTokenOwner(_tokenId)
    {
        uint256 reward = rewards[_tokenId];
        if (reward > 0) {
            rewards[_tokenId] = 0;
            rewardsToken.transfer(deposits[_tokenId].owner, reward);
            emit RewardPaid(deposits[_tokenId].owner, _tokenId, reward);
        }
    }

    function getReward(address account, address[] memory)
        external
        override
        nonReentrant
    {
        for (uint256 index = 0; index < balanceOf[account]; index++) {
            uint256 tokenId = _ownedTokens[account][index];
            getReward(tokenId);
        }
    }

    function exit(uint256 _tokenId) external {
        withdraw(_tokenId);
        getReward(_tokenId);
    }

    /// @notice Upon receiving a Uniswap V3 ERC721, creates the token deposit setting owner to `from`. Also stakes token
    /// in one or more incentives if properly formatted `data` has a length > 0.
    function _onERC721Received(address _from, uint256 _tokenId)
        internal
        updateReward(_tokenId)
    {
        require(
            msg.sender == address(nonfungiblePositionManager),
            "not called from nft manager"
        );
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

        uint128 _derivedLiquidity = derivedLiquidity(liquidity, _from);

        deposits[_tokenId] = Deposit({
            owner: _from,
            liquidity: liquidity,
            derivedLiquidity: _derivedLiquidity
        });

        _addTokenToAllTokensEnumeration(_tokenId);
        _addTokenToOwnerEnumeration(_from, _tokenId);

        balanceOf[_from] += 1;
        totalSupply = totalSupply.add(_derivedLiquidity);

        if (!attached[_from]) {
            attached[_from] = true;
            IGaugeVoterV2(registry.gaugeVoter()).attachStakerToGauge(_from);
        }

        emit Staked(msg.sender, _tokenId, liquidity, _derivedLiquidity);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(address, uint256 reward)
        external
        override
        updateReward(0)
    {
        require(msg.sender == registry.gaugeVoter(), "not gauge voter");

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
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function _updateLiquidity(uint256 _tokenId) private {
        (, , , uint128 _liquidity) = NFTPositionInfo.getPositionInfo(
            factory,
            nonfungiblePositionManager,
            _tokenId
        );

        if (_liquidity == deposits[_tokenId].liquidity) return;

        address _who = deposits[_tokenId].owner;
        uint128 _derivedLiquidity = derivedLiquidity(_liquidity, _who);

        // remove old, add new derived liquidity
        totalSupply = totalSupply.add(_derivedLiquidity).sub(
            deposits[_tokenId].derivedLiquidity
        );

        deposits[_tokenId].liquidity = _liquidity;
        deposits[_tokenId].derivedLiquidity = _derivedLiquidity;
    }

    function _getLiquidityAndInRange(uint256 _tokenId)
        private
        view
        returns (
            IUniswapV3Pool pool,
            bool inRange,
            uint128 liquidity
        )
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

        pool = _pool;
        inRange = _tickLower <= tick && tick >= _tickUpper;
        liquidity = _liquidity;
    }

    /* ========== MODIFIERS ========== */

    function _updateReward(uint256 _tokenId) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_tokenId != 0) {
            rewards[_tokenId] = earned(_tokenId);
            userRewardPerTokenPaid[_tokenId] = rewardPerTokenStored;
            _updateLiquidity(_tokenId);
        }
    }

    modifier updateReward(uint256 _tokenId) {
        _updateReward(_tokenId);
        _;
    }

    function updateRewardFor(uint256 _tokenId) external {
        require(deposits[_tokenId].liquidity > 0, "liquidity is 0");
        _updateReward(_tokenId);
    }
}