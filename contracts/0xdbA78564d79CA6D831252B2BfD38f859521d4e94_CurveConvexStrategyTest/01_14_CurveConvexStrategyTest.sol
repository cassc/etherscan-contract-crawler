// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../../interfaces/IExchange.sol";
import "../../interfaces/IWrappedEther.sol";

import "hardhat/console.sol";

interface IAlluoStrategy {
    /// @notice Invest tokens transferred to this contract.
    /// @dev Amount of tokens specified in `amount` is guranteed to be
    /// transferred to strategy by vote executor.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param amount amount of your tokens that will be invested.
    /// @return data that MUST be passed in exiting functions
    function invest(bytes calldata data, uint256 amount)
        external
        returns (bytes memory);

    /// @notice Uninvest value and tranfer exchanged value to receiver.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param unwindPercent percentage of available assets to be released with 2 decimal points.
    /// @param outputCoin address of token that strategy MUST return.
    /// @param receiver address where tokens should go.
    /// @param swapRewards true if rewards are needed to swap to `outputCoin`, false otherwise.
    function exitAll(
        bytes calldata data,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external;

    /// @notice Claim available rewards.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param outputCoin address of token that strategy MUST return (if swapRewards is true).
    /// @param receiver address where tokens should go.
    /// @param swapRewards true if rewards are needed to swap to `outputCoin`, false otherwise.
    function exitOnlyRewards(
        bytes calldata data,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external;

    /// @notice Execute any action on behalf of strategy.
    /// @dev Regular call is executed. If any of extcall fails, transaction should revert.
    /// @param destinations addresses to call
    /// @param calldatas calldatas to execute
    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external;
}
interface ICvxBooster {
    function FEE_DENOMINATOR() external view returns (uint256);

    function MaxFees() external view returns (uint256);

    function addPool(
        address _lptoken,
        address _gauge,
        uint256 _stashVersion
    ) external returns (bool);

    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    function crv() external view returns (address);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function distributionAddressId() external view returns (uint256);

    function earmarkFees() external returns (bool);

    function earmarkIncentive() external view returns (uint256);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function feeDistro() external view returns (address);

    function feeManager() external view returns (address);

    function feeToken() external view returns (address);

    function gaugeMap(address) external view returns (bool);

    function isShutdown() external view returns (bool);

    function lockFees() external view returns (address);

    function lockIncentive() external view returns (uint256);

    function lockRewards() external view returns (address);

    function minter() external view returns (address);

    function owner() external view returns (address);

    function platformFee() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function poolLength() external view returns (uint256);

    function poolManager() external view returns (address);

    function registry() external view returns (address);

    function rewardArbitrator() external view returns (address);

    function rewardClaimed(
        uint256 _pid,
        address _address,
        uint256 _amount
    ) external returns (bool);

    function rewardFactory() external view returns (address);

    function setArbitrator(address _arb) external;

    function setFactories(
        address _rfactory,
        address _sfactory,
        address _tfactory
    ) external;

    function setFeeInfo() external;

    function setFeeManager(address _feeM) external;

    function setFees(
        uint256 _lockFees,
        uint256 _stakerFees,
        uint256 _callerFees,
        uint256 _platform
    ) external;

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function setOwner(address _owner) external;

    function setPoolManager(address _poolM) external;

    function setRewardContracts(address _rewards, address _stakerRewards)
        external;

    function setTreasury(address _treasury) external;

    function setVoteDelegate(address _voteDelegate) external;

    function shutdownPool(uint256 _pid) external returns (bool);

    function shutdownSystem() external;

    function staker() external view returns (address);

    function stakerIncentive() external view returns (uint256);

    function stakerRewards() external view returns (address);

    function stashFactory() external view returns (address);

    function tokenFactory() external view returns (address);

    function treasury() external view returns (address);

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool);

    function voteDelegate() external view returns (address);

    function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight)
        external
        returns (bool);

    function voteOwnership() external view returns (address);

    function voteParameter() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external returns (bool);
}


interface ICvxBaseRewardPool {
    function addExtraReward(address _reward) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function clearExtraRewards() external;

    function currentRewards() external view returns (uint256);

    function donate(uint256 _amount) external returns (bool);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    function historicalRewards() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function newRewardRatio() external view returns (uint256);

    function operator() external view returns (address);

    function periodFinish() external view returns (uint256);

    function pid() external view returns (uint256);

    function queueNewRewards(uint256 _rewards) external returns (bool);

    function queuedRewards() external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);
}

    interface ICurve2Pool {
    // add liquidity (dai or usdc) to receive back DAI+USDC
    function add_liquidity(uint256[2] memory _deposit_amounts, uint256 _min_mint_amount) external returns(uint256);
    // remove liquidity (DAI+USDC) to recieve back dai or usdc
    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_amount) external returns(uint256);
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns(uint256);
    function coins(uint256 index) external view returns(address);
}
contract CurveConvexStrategyTest is AccessControl, IAlluoStrategy {
    using Address for address;
    using SafeERC20 for IERC20;
    // For polygon remember to change these constants


    ICvxBooster public constant cvxBooster =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);
    IERC20 public constant cvxRewards =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 public constant crvRewards =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    // IERC20 public constant crvRewards =
    //     IERC20(0x1E4F97b9f9F913c46F1632781732927B9019C68b);

    IWrappedEther public constant wETH =
        IWrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        
    constructor(
        address voteExecutor,
        address gnosis
    ) {
            require(
                voteExecutor.isContract(),
                "CurveConvexStrategy: 1!contract"
            );
            require(gnosis.isContract(), "CurveConvexStrategy: 2!contract");
            _grantRole(DEFAULT_ADMIN_ROLE, gnosis);
            _grantRole(DEFAULT_ADMIN_ROLE, voteExecutor);

    }

    receive() external payable {
    }

    function invest(bytes calldata data, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes memory)
    {
        (
            address curvePool,
            IERC20 lpToken,
            IERC20 poolToken,
            uint8 poolSize,
            uint8 tokenIndexInCurve,
            uint256 poolId
        ) = decodeEntryParams(data);
        uint256 valueETH;
        
        if (address(poolToken) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            wETH.withdraw(amount);
            valueETH = amount;
        } else {
            poolToken.safeIncreaseAllowance(curvePool, amount);
        }
        uint256[4] memory fourPoolTokensAmount;
        fourPoolTokensAmount[tokenIndexInCurve] = amount;
        bytes memory curveCall;
      

      if (poolSize == 2 ) {
            curveCall = abi.encodeWithSelector(
                0x0b4c7e4d,
                uint256[2]([fourPoolTokensAmount[0], fourPoolTokensAmount[1]]),
                0
            );
        }  else if (poolSize == 3) {
            curveCall = abi.encodeWithSelector(
                0x4515cef3,
                uint256[3](
                    [
                        fourPoolTokensAmount[0],
                        fourPoolTokensAmount[1],
                        fourPoolTokensAmount[2]
                    ]
                ),
                0
            );
        } else {
            curveCall = abi.encodeWithSelector(
                0x029b2f34,
                fourPoolTokensAmount,
                0
            );
        }

        curvePool.functionCallWithValue(curveCall, valueETH);

        // skip investment in convex, if poolId is uint256 max value
        if (poolId != type(uint256).max) {
            // invest tokens to convex
            uint256 lpAmount = lpToken.balanceOf(address(this));
            lpToken.safeIncreaseAllowance(address(cvxBooster), lpAmount);
            cvxBooster.deposit(poolId, lpAmount, true);
        }

        return
            encodeExitParams(
                curvePool,
                address(lpToken),
                address(poolToken),
                // Placeholder! Make sure to change.
                "int128",
                tokenIndexInCurve,
                poolId
            );
    }

    
    function exitAll(
        bytes calldata data,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (
            address curvePool,
            IERC20 lpToken,
            IERC20 poolToken,
            bytes memory typeOfTokenIndex,
            uint8 tokenIndexInCurve,
            uint256 convexPoolId
        ) = decodeExitParams(data);
        uint256 lpAmount;
        if (convexPoolId != type(uint256).max) {
            ICvxBaseRewardPool rewards = getCvxRewardPool(convexPoolId);
            lpAmount =
                (rewards.balanceOf(address(this)) * unwindPercent) / 10000;

            // withdraw Curve LPs and all rewards
            rewards.withdrawAndUnwrap(lpAmount, true);
        } else {
            lpAmount = lpToken.balanceOf(address(this)) * unwindPercent / 10000;
        }

        if (lpAmount == 0) return;
        // exit with coin that we used for entry
        bytes memory curveCall = abi.encodeWithSignature(
            string(bytes.concat("remove_liquidity_one_coin(uint256,", typeOfTokenIndex,",uint256)")),
            lpAmount,
            tokenIndexInCurve,
            0
        );
        uint256  valueETHBefore = address(this).balance;
        curvePool.functionCall(curveCall);
        uint256 ethDelta = address(this).balance - valueETHBefore;
        if (ethDelta > 0) {
            wETH.deposit{value: ethDelta}();
            poolToken = IERC20(address(wETH));
        } 
        // execute exchanges and transfer all tokens to receiver
        exchangeAll(poolToken, IERC20(outputCoin));
        manageRewardsAndWithdraw(swapRewards, IERC20(outputCoin), receiver);
    }

    function exitOnlyRewards(
        bytes calldata data,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (, , , , , uint256 convexPoolId) = decodeExitParams(data);
        ICvxBaseRewardPool rewards = getCvxRewardPool(convexPoolId);
        rewards.getReward(address(this), true);

        manageRewardsAndWithdraw(swapRewards, IERC20(outputCoin), receiver);
    }

    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = destinations.length;
        require(length == calldatas.length, "CurveConvexStrategy: lengths");
        for (uint256 i = 0; i < length; i++) {
            destinations[i].functionCall(calldatas[i]);
        }
    }

    function encodeEntryParams(
        address curvePool,
        address lpToken,
        address poolToken,
        uint8 poolSize,
        uint8 tokenIndexInCurve,
        uint256 convexPoolId
    ) external pure returns (bytes memory) {
        return
            abi.encode(
                curvePool,
                lpToken,
                poolToken,
                poolSize,
                tokenIndexInCurve,
                convexPoolId
            );
    }

    function encodeExitParams(
        address curvePool,
        address lpToken,
        address poolToken,
        bytes memory typeOfTokenIndex,
        uint8 tokenIndexInCurve,
        uint256 convexPoolId
    ) public pure returns (bytes memory) {
        return
            abi.encode(
                curvePool,
                lpToken,
                poolToken,
                typeOfTokenIndex,
                tokenIndexInCurve,
                convexPoolId
            );
    }

    function decodeEntryParams(bytes calldata data)
        public
        pure
        returns (
            address,
            IERC20,
            IERC20,
            uint8,
            uint8,
            uint256
        )
    {
        require(data.length == 32 * 6, "CurveConvexStrategy: length en");
        return
            abi.decode(data, (address, IERC20, IERC20, uint8, uint8, uint256));
    }

    function decodeExitParams(bytes calldata data)
        public
        pure
        returns (
            address,
            IERC20,
            IERC20,
            bytes memory,
            uint8,
            uint256
        )
    {
        require(data.length == 32 * 8, "CurveConvexStrategy: length ex");
        return abi.decode(data, (address, IERC20, IERC20, bytes, uint8, uint256));
    }

    function exchangeAll(IERC20 fromCoin, IERC20 toCoin) private {
        if (fromCoin == toCoin) return;
        uint256 amount = IERC20(fromCoin).balanceOf(address(this));
        if (amount == 0) return;

        fromCoin.safeApprove(address(exchange), amount);
        exchange.exchange(address(fromCoin), address(toCoin), amount, 0);
    }

    function manageRewardsAndWithdraw(
        bool swapRewards,
        IERC20 outputCoin,
        address receiver
    ) private {
        if (swapRewards) {
            exchangeAll(cvxRewards, outputCoin);
            exchangeAll(crvRewards, outputCoin);
        } else {
            cvxRewards.safeTransfer(
                receiver,
                cvxRewards.balanceOf(address(this))
            );
            crvRewards.safeTransfer(
                receiver,
                crvRewards.balanceOf(address(this))
            );
        }

        outputCoin.safeTransfer(receiver, outputCoin.balanceOf(address(this)));
    }

    function getCvxRewardPool(uint256 poolId)
        private
        view
        returns (ICvxBaseRewardPool)
    {
        (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
        return ICvxBaseRewardPool(pool);
    }
}