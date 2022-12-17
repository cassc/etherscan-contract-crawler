// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IVaultStrategy.sol";
import "../interfaces/IHedgepieInvestorBsc.sol";
import "../interfaces/IHedgepieAdapterInfoBsc.sol";
import "../interfaces/IStargateReceiver.sol";

import "../libraries/HedgepieLibraryBsc.sol";

interface IStrategy {
    function pendingAUTO(uint256 pid, address user)
        external
        view
        returns (uint256);

    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256, uint256);

    function deposit(uint256 pid, uint256 shares) external;

    function withdraw(uint256 pid, uint256 shares) external;
}

contract AutoVaultAdapterBscMock is BaseAdapterBsc, IStargateReceiver {
    // vStrategy address of vault
    address public vStrategy;

    // Address bridge token
    address public starToken;

    /**
     * @notice Construct
     * @param _pid pool id of strategy
     * @param _strategy  address of strategy
     * @param _vStrategy  address of vault strategy
     * @param _stakingToken  address of staking token
     * @param _router  address of DEX router
     * @param _swapRouter  address of swap router
     * @param _wbnb  address of wbnb
     * @param _name  adatper name
     */
    constructor(
        uint256 _pid,
        address _strategy,
        address _vStrategy,
        address _stakingToken,
        address _router,
        address _swapRouter,
        address _wbnb,
        string memory _name
    ) {
        pid = _pid;
        strategy = _strategy;
        vStrategy = _vStrategy;
        stakingToken = _stakingToken;
        router = _router;
        swapRouter = _swapRouter;
        wbnb = _wbnb;
        name = _name;
    }

    /**
     * @notice Deposit with Bnb
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     * @param _amountIn Bnb amount
     */
    function deposit(
        uint256 _tokenId,
        uint256 _amountIn,
        address _account
    ) public payable override returns (uint256 amountOut) {
        AdapterInfo storage adapterInfo = adapterInfos[_tokenId];
        UserAdapterInfo storage userInfo = userAdapterInfos[_account][_tokenId];

        // get LP
        amountOut = HedgepieLibraryBsc.getLP(
            IYBNFT.Adapter(0, stakingToken, address(this), 0, 0),
            wbnb,
            _amountIn
        );

        // deposit
        (uint256 beforeShare, ) = IStrategy(strategy).userInfo(
            pid,
            address(this)
        );
        IBEP20(stakingToken).approve(strategy, amountOut);
        IStrategy(strategy).deposit(pid, amountOut);
        (uint256 afterShare, ) = IStrategy(strategy).userInfo(
            pid,
            address(this)
        );

        adapterInfo.totalStaked += amountOut;
        userInfo.amount += amountOut;
        userInfo.userShares += afterShare - beforeShare;
        userInfo.invested += _amountIn;

        // // Update adapterInfo contract
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
        UserAdapterInfo memory userInfo = userAdapterInfos[_account][_tokenId];

        // withdraw from MasterChef
        uint256 vAmount = (userInfo.userShares *
            IVaultStrategy(vStrategy).wantLockedTotal()) /
            IVaultStrategy(vStrategy).sharesTotal();
        uint256 lpOut = IBEP20(stakingToken).balanceOf(address(this));
        IStrategy(strategy).withdraw(pid, vAmount);

        unchecked {
            lpOut = IBEP20(stakingToken).balanceOf(address(this)) - lpOut;
        }

        amountOut = HedgepieLibraryBsc.withdrawLP(
            IYBNFT.Adapter(0, stakingToken, address(this), 0, 0),
            wbnb,
            lpOut
        );

        address adapterInfoBnbAddr = IHedgepieInvestorBsc(investor)
            .adapterInfo();

        uint256 reward;
        if (amountOut > userInfo.invested) {
            reward = amountOut - userInfo.invested;

            IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateProfitInfo(
                _tokenId,
                reward,
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

        unchecked {
            adapterInfo.totalStaked -= userInfo.amount;
        }

        delete userAdapterInfos[_account][_tokenId];

        if (amountOut != 0) {
            bool success;
            if (reward != 0) {
                reward =
                    (reward *
                        IYBNFT(IHedgepieInvestorBsc(investor).ybnft())
                            .performanceFee(_tokenId)) /
                    1e4;
                (success, ) = payable(IHedgepieInvestorBsc(investor).treasury())
                    .call{value: reward}("");
                require(success, "Failed to send bnb to Treasury");
            }

            (success, ) = payable(_account).call{value: amountOut - reward}("");
            require(success, "Failed to send bnb");
        }
    }

    /**
     * @notice Return the pending reward by BNB
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     */
    function pendingReward(uint256 _tokenId, address _account)
        public
        view
        override
        returns (uint256 reward)
    {
        UserAdapterInfo memory userInfo = userAdapterInfos[_account][_tokenId];

        uint256 vAmount = (userInfo.userShares *
            IVaultStrategy(vStrategy).wantLockedTotal()) /
            IVaultStrategy(vStrategy).sharesTotal();

        if (vAmount < userInfo.amount) return 0;

        address token0 = IPancakePair(stakingToken).token0();
        address token1 = IPancakePair(stakingToken).token1();
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(stakingToken)
            .getReserves();

        uint256 amount0 = (reserve0 * (vAmount - userInfo.amount)) /
            IPancakePair(stakingToken).totalSupply();
        uint256 amount1 = (reserve1 * (vAmount - userInfo.amount)) /
            IPancakePair(stakingToken).totalSupply();

        if (token0 == wbnb) reward += amount0;
        else
            reward += IPancakeRouter(swapRouter).getAmountsOut(
                amount0,
                getPaths(token0, wbnb)
            )[1];

        if (token1 == wbnb) reward += amount1;
        else
            reward += IPancakeRouter(swapRouter).getAmountsOut(
                amount1,
                getPaths(token1, wbnb)
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