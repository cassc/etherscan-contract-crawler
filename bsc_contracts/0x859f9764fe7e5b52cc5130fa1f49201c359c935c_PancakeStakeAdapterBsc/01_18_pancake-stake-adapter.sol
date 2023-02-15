// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libraries/HedgepieLibraryBsc.sol";
import "../../../interfaces/IHedgepieInvestorBsc.sol";
import "../../../interfaces/IHedgepieAdapterInfoBsc.sol";

interface IStrategy {
    function pendingReward(address _user) external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

contract PancakeStakeAdapterBsc is BaseAdapterBsc {
    /**
     * @notice Construct
     * @param _strategy  address of strategy
     * @param _stakingToken  address of staking token
     * @param _swapRouter  address of swap router
     * @param _rewardToken  address of reward token
     * @param _wbnb  address of wbnb
     * @param _name  name of adapter
     */
    constructor(
        address _strategy,
        address _stakingToken,
        address _rewardToken,
        address _swapRouter,
        address _wbnb,
        string memory _name
    ) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        swapRouter = _swapRouter;
        strategy = _strategy;
        wbnb = _wbnb;
        name = _name;
    }

    /**
     * @notice Deposit with BNB
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     */
    function deposit(uint256 _tokenId, address _account)
        external
        payable
        override
        onlyInvestor
        returns (uint256 amountOut)
    {
        uint256 _amountIn = msg.value;

        UserAdapterInfo storage userInfo = userAdapterInfos[_account][_tokenId];

        if (router == address(0)) {
            amountOut = HedgepieLibraryBsc.swapOnRouter(
                _amountIn,
                address(this),
                stakingToken,
                swapRouter,
                wbnb
            );
        } else {
            amountOut = HedgepieLibraryBsc.getLP(
                IYBNFT.Adapter(0, stakingToken, address(this)),
                wbnb,
                _amountIn
            );
        }
        uint256 rewardAmt0;

        rewardAmt0 = IBEP20(rewardToken).balanceOf(address(this));

        IBEP20(stakingToken).approve(strategy, amountOut);
        IStrategy(strategy).deposit(amountOut);

        rewardAmt0 = IBEP20(rewardToken).balanceOf(address(this)) - rewardAmt0;

        if (
            rewardAmt0 != 0 &&
            rewardToken != address(0) &&
            mAdapter.totalStaked != 0
        ) {
            mAdapter.accTokenPerShare +=
                (rewardAmt0 * 1e12) /
                mAdapter.totalStaked;
        }
        mAdapter.totalStaked += amountOut;

        if (userInfo.amount != 0) {
            userInfo.rewardDebt +=
                (userInfo.amount *
                    (mAdapter.accTokenPerShare - userInfo.userShares)) /
                1e12;
        }
        userInfo.userShares = mAdapter.accTokenPerShare;
        userInfo.amount += amountOut;
        userInfo.invested += _amountIn;

        // Update adapterInfo contract
        address adapterInfoBnbAddr = IHedgepieInvestorBsc(investor)
            .adapterInfo();
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTVLInfo(
            _tokenId,
            _amountIn,
            true
        );
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTradedInfo(
            _tokenId,
            _amountIn,
            true
        );
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateParticipantInfo(
            _tokenId,
            _account,
            true
        );

        return _amountIn;
    }

    /**
     * @notice Withdraw the deposited Bnb
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     */
    function withdraw(uint256 _tokenId, address _account)
        external
        payable
        override
        onlyInvestor
        returns (uint256 amountOut)
    {
        UserAdapterInfo storage userInfo = userAdapterInfos[_account][_tokenId];

        uint256 rewardAmt0;
        amountOut = IBEP20(stakingToken).balanceOf(address(this));

        rewardAmt0 = IBEP20(rewardToken).balanceOf(address(this));

        IBEP20(stakingToken).approve(strategy, amountOut);
        IStrategy(strategy).withdraw(userInfo.amount);

        rewardAmt0 = IBEP20(rewardToken).balanceOf(address(this)) - rewardAmt0;
        amountOut = IBEP20(stakingToken).balanceOf(address(this)) - amountOut;

        if (
            rewardAmt0 != 0 &&
            rewardToken != address(0) &&
            mAdapter.totalStaked != 0
        ) {
            mAdapter.accTokenPerShare +=
                (rewardAmt0 * 1e12) /
                mAdapter.totalStaked;
        }

        if (router == address(0)) {
            amountOut = HedgepieLibraryBsc.swapforBnb(
                amountOut,
                address(this),
                stakingToken,
                swapRouter,
                wbnb
            );
        } else {
            amountOut = HedgepieLibraryBsc.withdrawLP(
                IYBNFT.Adapter(0, stakingToken, address(this)),
                wbnb,
                amountOut
            );
        }

        (uint256 reward, ) = HedgepieLibraryBsc.getMRewards(
            _tokenId,
            address(this),
            _account
        );

        uint256 rewardBnb;
        if (reward != 0) {
            rewardBnb = HedgepieLibraryBsc.swapforBnb(
                reward,
                address(this),
                rewardToken,
                swapRouter,
                wbnb
            );
        }

        address adapterInfoBnbAddr = IHedgepieInvestorBsc(investor)
            .adapterInfo();
        if (rewardBnb != 0) {
            amountOut += rewardBnb;
            IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateProfitInfo(
                _tokenId,
                rewardBnb,
                true
            );
        }

        // Update adapterInfo contract
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTVLInfo(
            _tokenId,
            userInfo.invested,
            false
        );
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTradedInfo(
            _tokenId,
            userInfo.invested,
            true
        );
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateParticipantInfo(
            _tokenId,
            _account,
            false
        );

        mAdapter.totalStaked -= userInfo.amount;
        delete userAdapterInfos[_account][_tokenId];

        if (amountOut != 0) {
            bool success;
            if (rewardBnb != 0) {
                rewardBnb =
                    (rewardBnb *
                        IYBNFT(IHedgepieInvestorBsc(investor).ybnft())
                            .performanceFee(_tokenId)) /
                    1e4;
                (success, ) = payable(IHedgepieInvestorBsc(investor).treasury())
                    .call{value: rewardBnb}("");
                require(success, "Failed to send bnb to Treasury");
            }

            (success, ) = payable(_account).call{value: amountOut - rewardBnb}(
                ""
            );
            require(success, "Failed to send bnb");
        }
    }

    /**
     * @notice Claim the pending reward
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     */
    function claim(uint256 _tokenId, address _account)
        external
        payable
        override
        onlyInvestor
        returns (uint256 amountOut)
    {
        UserAdapterInfo storage userInfo = userAdapterInfos[_account][_tokenId];

        // claim rewards
        uint256 rewardAmt0 = IBEP20(rewardToken).balanceOf(address(this));
        IStrategy(strategy).withdraw(0);
        rewardAmt0 = IBEP20(rewardToken).balanceOf(address(this)) - rewardAmt0;
        if (
            rewardAmt0 != 0 &&
            rewardToken != address(0) &&
            mAdapter.totalStaked != 0
        ) {
            mAdapter.accTokenPerShare +=
                (rewardAmt0 * 1e12) /
                mAdapter.totalStaked;
        }

        (uint256 reward, ) = HedgepieLibraryBsc.getMRewards(
            _tokenId,
            address(this),
            _account
        );

        userInfo.userShares = mAdapter.accTokenPerShare;
        userInfo.rewardDebt = 0;

        if (reward != 0 && rewardToken != address(0)) {
            amountOut += HedgepieLibraryBsc.swapforBnb(
                reward,
                address(this),
                rewardToken,
                swapRouter,
                wbnb
            );

            uint256 taxAmount = (amountOut *
                IYBNFT(IHedgepieInvestorBsc(investor).ybnft()).performanceFee(
                    _tokenId
                )) / 1e4;
            (bool success, ) = payable(
                IHedgepieInvestorBsc(investor).treasury()
            ).call{value: taxAmount}("");
            require(success, "Failed to send bnb to Treasury");

            (success, ) = payable(_account).call{value: amountOut - taxAmount}(
                ""
            );
            require(success, "Failed to send bnb");

            IHedgepieAdapterInfoBsc(
                IHedgepieInvestorBsc(investor).adapterInfo()
            ).updateProfitInfo(_tokenId, amountOut, true);
        }
    }

    /**
     * @notice Return the pending reward by Bnb
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     */
    function pendingReward(uint256 _tokenId, address _account)
        external
        view
        override
        returns (uint256 reward, uint256 withdrawable)
    {
        UserAdapterInfo memory userInfo = userAdapterInfos[_account][_tokenId];

        uint256 updatedAccTokenPerShare = mAdapter.accTokenPerShare +
            ((IStrategy(strategy).pendingReward(address(this)) * 1e12) /
                mAdapter.totalStaked);

        uint256 tokenRewards = ((updatedAccTokenPerShare -
            userInfo.userShares) * userInfo.amount) /
            1e12 +
            userInfo.rewardDebt;

        if (tokenRewards != 0) {
            reward = rewardToken == wbnb
                ? tokenRewards
                : IPancakeRouter(swapRouter).getAmountsOut(
                    tokenRewards,
                    getPaths(rewardToken, wbnb)
                )[getPaths(rewardToken, wbnb).length - 1];
            withdrawable = reward;
        }
    }

    receive() external payable {}
}