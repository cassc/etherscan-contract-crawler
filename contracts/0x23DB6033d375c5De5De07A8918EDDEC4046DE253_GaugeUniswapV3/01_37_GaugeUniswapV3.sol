// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IGauge} from "../../interfaces/IGauge.sol";
import {IGaugeVoterV2} from "../../interfaces/IGaugeVoterV2.sol";
import {INFTStaker} from "../../interfaces/INFTStaker.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";
import {NFTPositionInfo} from "../../utils/NFTPositionInfo.sol";
import {UniswapV3Base} from "./UniswapV3Base.sol";
import {VersionedInitializable} from "../../proxy/VersionedInitializable.sol";

import "hardhat/console.sol";

contract GaugeUniswapV3 is
    VersionedInitializable,
    UniswapV3Base,
    IERC721Receiver
{
    using SafeMath for uint256;
    using SafeMath for uint128;

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
            _nonfungiblePositionManager,
            _treasury
        );
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 2;
    }

    function earned(uint256 _tokenId) public view returns (uint256) {
        return
            deposits[_tokenId]
                .derivedLiquidity
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_tokenId]))
                .div(1e18)
                .add(rewards[_tokenId]);
    }

    function derivedLiquidity(uint128 _liquidity, address account)
        public
        view
        returns (uint256)
    {
        uint128 _normalLiquidity = (_liquidity * 20) / 100;
        uint256 stake = INFTStaker(registry.staker()).balanceOf(account);

        uint256 _boost = ((_liquidity * stake * 80) / maxBoostRequirement) /
            100;

        // because of this we are able to max out the boost by 5x
        return Math.min(_normalLiquidity + _boost, _liquidity);
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

    /* ========== MUTATIVE FUNCTIONS ========== */

    function withdraw(uint256 tokenId)
        public
        nonReentrant
        updateReward(tokenId)
        onlyTokenOwner(tokenId)
    {
        // claim fees for the treasury
        _claimFees(tokenId);

        require(deposits[tokenId].liquidity > 0, "Cannot withdraw 0");
        totalSupply = totalSupply.sub(deposits[tokenId].derivedLiquidity);
        delete deposits[tokenId];

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

    function getReward(uint256 _tokenId)
        public
        nonReentrant
        updateReward(_tokenId)
        onlyTokenOwner(_tokenId)
    {
        uint256 reward = rewards[_tokenId];
        if (reward > 0) {
            rewards[_tokenId] = 0;
            IERC20(registry.maha()).transfer(deposits[_tokenId].owner, reward);
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

    function claimFeesMultiple(uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) _claimFees(_tokenIds[i]);
    }

    function claimFees(uint256 _tokenId) external {
        _claimFees(_tokenId);
    }

    /// @notice Upon receiving a Uniswap V3 ERC721, creates the token deposit setting owner to `from`. Also stakes token
    /// in one or more incentives if properly formatted `data` has a length > 0.
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        require(
            msg.sender == address(nonfungiblePositionManager),
            "not called from nft manager"
        );
        _onERC721Received(from, tokenId);
        return this.onERC721Received.selector;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(address, uint256 reward)
        external
        override
        updateReward(0)
    {
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

    function _onERC721Received(address _from, uint256 _tokenId) internal {
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

        uint256 _derivedLiquidity = derivedLiquidity(liquidity, _from);

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

        // update rewards
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewards[_tokenId] = earned(_tokenId);
        userRewardPerTokenPaid[_tokenId] = rewardPerTokenStored;

        emit Staked(msg.sender, _tokenId, liquidity, _derivedLiquidity);
    }

    function _claimFees(uint256 _tokenId) internal {
        // send fees to the treasury
        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        // send 50% to the owner, 50% to the DAO
        address owner = deposits[_tokenId].owner;
        if (amount0 > 0) {
            IERC20(token0).transfer(owner, amount0 / 2);
            IERC20(token0).transfer(treasury, amount0 / 2);
        }
        if (amount1 > 0) {
            IERC20(token1).transfer(owner, amount1 / 2);
            IERC20(token1).transfer(treasury, amount1 / 2);
        }
    }

    function _updateLiquidity(uint256 _tokenId) private {
        (, , , uint128 _liquidity) = NFTPositionInfo.getPositionInfo(
            factory,
            nonfungiblePositionManager,
            _tokenId
        );

        if (_liquidity == deposits[_tokenId].liquidity) return;

        address _who = deposits[_tokenId].owner;
        uint256 _derivedLiquidity = derivedLiquidity(_liquidity, _who);

        // remove old, add new derived liquidity
        totalSupply = totalSupply.add(_derivedLiquidity).sub(
            deposits[_tokenId].derivedLiquidity
        );

        // update old
        deposits[_tokenId].liquidity = _liquidity;
        deposits[_tokenId].derivedLiquidity = _derivedLiquidity;
    }

    function _getLiquidityAndInRange(uint256 _tokenId)
        private
        view
        returns (
            IUniswapV3Pool _p,
            bool _inRange,
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

        _p = _pool;
        _inRange = _tickLower <= tick && tick <= _tickUpper;
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

        console.log("updateRewards -> rpt", rewardPerTokenStored);
        console.log("updateRewards -> lastUpdateTime", lastUpdateTime);
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