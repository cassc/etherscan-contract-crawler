// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/HedgepieLibraryBsc.sol";
import "../interfaces/IHedgepieInvestorBsc.sol";
import "../interfaces/IHedgepieAdapterInfoBsc.sol";
import "../interfaces/IStargateReceiver.sol";

interface IStrategy {
    function pendingBSW(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function enterStaking(uint256 amount) external;

    function leaveStaking(uint256 amount) external;
}

contract BiSwapFarmLPAdapterBscMock is BaseAdapterBsc, IStargateReceiver {
    /**
     * @notice Construct
     * @param _strategy  address of strategy
     * @param _stakingToken  address of staking token
     * @param _rewardToken  address of reward token
     * @param _router  address of biswap
     * @param _swapRouter  address of swap router
     * @param _wbnb  address of wbnb
     * @param _name  adatper name
     */
    constructor(
        uint256 _pid,
        address _strategy,
        address _stakingToken,
        address _rewardToken,
        address _router,
        address _swapRouter,
        address _wbnb,
        string memory _name
    ) {
        pid = _pid;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        strategy = _strategy;
        router = _router;
        swapRouter = _swapRouter;
        wbnb = _wbnb;
        name = _name;
    }

    /**
     * @notice Deposit with BNB
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     * @param _amountIn BNB amount
     */
    function deposit(
        uint256 _tokenId,
        uint256 _amountIn,
        address _account
    ) public payable override returns (uint256 amountOut) {
        AdapterInfo storage adapterInfo = adapterInfos[_tokenId];
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
                IYBNFT.Adapter(0, stakingToken, address(this), 0, 0),
                wbnb,
                _amountIn
            );
        }
        uint256 rewardAmt0;

        rewardAmt0 = IBEP20(rewardToken).balanceOf(address(this));

        IBEP20(stakingToken).approve(strategy, amountOut);
        if (pid == 0) IStrategy(strategy).enterStaking(amountOut);
        else IStrategy(strategy).deposit(pid, amountOut);

        rewardAmt0 = pid == 0
            ? IBEP20(rewardToken).balanceOf(address(this)) +
                amountOut -
                rewardAmt0
            : IBEP20(rewardToken).balanceOf(address(this)) - rewardAmt0;

        adapterInfo.totalStaked += amountOut;
        if (rewardAmt0 != 0 && rewardToken != address(0)) {
            adapterInfo.accTokenPerShare +=
                (rewardAmt0 * 1e12) /
                adapterInfo.totalStaked;
        }

        if (userInfo.amount == 0) {
            userInfo.userShares = adapterInfo.accTokenPerShare;
            userInfo.userShares1 = adapterInfo.accTokenPerShare1;
        }
        userInfo.amount += amountOut;
        userInfo.invested += _amountIn;

        // Update adapterInfo contract
        // address adapterInfoBnbAddr = IHedgepieInvestorBsc(investor)
        //     .adapterInfo();
        // IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTVLInfo(
        //     _tokenId,
        //     _amountIn,
        //     true
        // );
        // IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTradedInfo(
        //     _tokenId,
        //     _amountIn,
        //     true
        // );
        // IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateParticipantInfo(
        //     _tokenId,
        //     _account,
        //     true
        // );
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
        returns (uint256 amountOut)
    {
        AdapterInfo storage adapterInfo = adapterInfos[_tokenId];
        UserAdapterInfo storage userInfo = userAdapterInfos[_account][_tokenId];

        uint256 rewardAmt0;
        amountOut = IBEP20(stakingToken).balanceOf(address(this));

        rewardAmt0 = IBEP20(rewardToken).balanceOf(address(this));

        IBEP20(stakingToken).approve(strategy, amountOut);

        if (pid == 0) IStrategy(strategy).leaveStaking(userInfo.amount);
        else IStrategy(strategy).withdraw(pid, userInfo.amount);

        rewardAmt0 = pid == 0
            ? IBEP20(rewardToken).balanceOf(address(this)) -
                rewardAmt0 -
                userInfo.amount
            : IBEP20(rewardToken).balanceOf(address(this)) - rewardAmt0;
        amountOut = pid == 0
            ? IBEP20(stakingToken).balanceOf(address(this)) -
                amountOut -
                rewardAmt0
            : IBEP20(stakingToken).balanceOf(address(this)) - amountOut;

        if (rewardAmt0 != 0 && rewardToken != address(0)) {
            adapterInfo.accTokenPerShare +=
                (rewardAmt0 * 1e12) /
                adapterInfo.totalStaked;
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
                IYBNFT.Adapter(0, stakingToken, address(this), 0, 0),
                wbnb,
                amountOut
            );
        }

        (uint256 reward, ) = HedgepieLibraryBsc.getRewards(
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

        adapterInfo.totalStaked -= userInfo.amount;
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
        returns (uint256 amountOut)
    {
        UserAdapterInfo storage userInfo = userAdapterInfos[_account][_tokenId];

        (uint256 reward, ) = HedgepieLibraryBsc.getRewards(
            _tokenId,
            address(this),
            _account
        );

        userInfo.userShares = adapterInfos[_tokenId].accTokenPerShare;
        userInfo.userShares1 = adapterInfos[_tokenId].accTokenPerShare1;

        if (reward != 0 && rewardToken != address(0)) {
            amountOut = HedgepieLibraryBsc.swapforBnb(
                reward,
                address(this),
                rewardToken,
                swapRouter,
                wbnb
            );
        }

        if (amountOut != 0) {
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
        returns (uint256 reward)
    {
        UserAdapterInfo memory userInfo = userAdapterInfos[_account][_tokenId];
        AdapterInfo memory adapterInfo = adapterInfos[_tokenId];

        uint256 updatedAccTokenPerShare = adapterInfo.accTokenPerShare +
            ((IStrategy(strategy).pendingBSW(pid, address(this)) * 1e12) /
                adapterInfo.totalStaked);

        uint256 tokenRewards = ((updatedAccTokenPerShare -
            userInfo.userShares) * userInfo.amount) / 1e12;

        if (tokenRewards != 0)
            reward = rewardToken == wbnb
                ? tokenRewards
                : IPancakeRouter(swapRouter).getAmountsOut(
                    tokenRewards,
                    getPaths(rewardToken, wbnb)
                )[1];
    }

    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        IBEP20(_token).approve(swapRouter, amountLD);

        uint256 amountOut = HedgepieLibraryBsc.swapforBnb(
            amountLD,
            address(this),
            _token,
            swapRouter,
            wbnb
        );
        require(amountOut != 0, "Error: Swap for bnb failed");

        address srcAddress;
        assembly {
            srcAddress := mload(add(_srcAddress, 20))
        }
        deposit(0, amountOut, srcAddress);

        emit sgReceived(
            _chainId,
            _srcAddress,
            _nonce,
            _token,
            amountLD,
            payload
        );
    }

    receive() external payable {}
}