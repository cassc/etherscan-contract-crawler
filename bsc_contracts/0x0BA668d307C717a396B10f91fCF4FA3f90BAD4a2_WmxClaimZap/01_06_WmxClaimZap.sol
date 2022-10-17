// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {WmxMath} from "./WmxMath.sol";
import {IWmxLocker, IWomDepositorWrapper} from "./Interfaces.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

interface IBasicRewards {
    function getReward(address _account, bool _lockWmx) external;

    function getReward(address _account) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function stakeFor(address, uint256) external;
}

/**
 * @title   ClaimZap
 * @author  ConvexFinance -> AuraFinance -> WombexFinance
 * @notice  Claim zap to bundle various reward claims
 * @dev     Claims from all pools, and stakes wmxWom and WMX if wanted.
 *          v2:
 *           - change exchange to use curve pool
 *           - add getReward(address,token) type
 *           - add option to lock wmx
 *           - add option use all funds in wallet
 */
contract WmxClaimZap {
    using SafeERC20 for IERC20;
    using WmxMath for uint256;

    address public immutable wom;
    address public immutable wmx;
    address public immutable womWmx;
    address public immutable womDepositor;
    address public immutable wmxWomRewards;
    address public immutable locker;
    address public immutable owner;

    enum Options {
        ClaimWmxWom, //1
        ClaimLockedWmx, //2
        ClaimLockedWmxStake, //4
        LockWomDeposit, //8
        UseAllWalletFunds, //16
        LockWmx, //32
        LockWmxRewards //64
    }

    /**
     * @param _wom                WOM token
     * @param _wmx                WMX token
     * @param _wmxWom             wmxWom token
     * @param _womDepositor         womDepositor
     * @param _wmxWomRewards      wmxWomRewards
     * @param _locker             vlWMX
     */
    constructor(
        address _wom,
        address _wmx,
        address _wmxWom,
        address _womDepositor,
        address _wmxWomRewards,
        address _locker
    ) {
        wom = _wom;
        wmx = _wmx;
        womWmx = _wmxWom;
        womDepositor = _womDepositor;
        wmxWomRewards = _wmxWomRewards;
        locker = _locker;
        owner = msg.sender;
    }

    function getName() external pure returns (string memory) {
        return "ClaimZap V2.0";
    }

    /**
     * @notice Approve spending of:
     *          wom     -> womDepositor
     *          wmxWom  -> wmxWomRewards
     *          wmx     -> Locker
     */
    function setApprovals() external {
        require(msg.sender == owner, "!auth");

        IERC20(wom).safeApprove(womDepositor, 0);
        IERC20(wom).safeApprove(womDepositor, type(uint256).max);

        IERC20(womWmx).safeApprove(wmxWomRewards, 0);
        IERC20(womWmx).safeApprove(wmxWomRewards, type(uint256).max);

        IERC20(wmx).safeApprove(locker, 0);
        IERC20(wmx).safeApprove(locker, type(uint256).max);
    }

    /**
     * @notice Use bitmask to check if option flag is set
     */
    function _checkOption(uint256 _mask, Options _flag) internal pure returns (bool) {
        return (_mask & (1 << uint256(_flag))) != 0;
    }

    /**
     * @notice Claim all the rewards
     * @param rewardContracts       Array of addresses for LP token rewards
     * @param extraRewardContracts  Array of addresses for extra rewards
     * @param tokenRewardContracts  Array of addresses for token rewards e.g vlWmxExtraRewardDistribution
     * @param tokenRewardPids       Array of token staking ids to use with tokenRewardContracts
     * @param depositWomMaxAmount   The max amount of WOM to deposit if converting to womWmx
     * @param minAmountOut          The min amount out for wom:wmxWom swaps if swapping. Set this to zero if you
     *                              want to use WomDepositor instead of balancer swap
     * @param depositWmxMaxAmount   The max amount of WMX to deposit if locking WMX
     * @param options               Claim options
     */
    function claimRewards(
        address[] calldata rewardContracts,
        address[] calldata extraRewardContracts,
        address[] calldata tokenRewardContracts,
        uint256[] calldata tokenRewardPids,
        uint256 depositWomMaxAmount,
        uint256 minAmountOut,
        uint256 depositWmxMaxAmount,
        uint256 options
    ) external {
        require(tokenRewardContracts.length == tokenRewardPids.length, "!parity");

        uint256 womBalance = IERC20(wom).balanceOf(msg.sender);
        uint256 wmxBalance = IERC20(wmx).balanceOf(msg.sender);

        //claim from main curve LP pools
        for (uint256 i = 0; i < rewardContracts.length; i++) {
            IBasicRewards(rewardContracts[i]).getReward(msg.sender, _checkOption(options, Options.LockWmxRewards));
        }
        //claim from extra rewards
        for (uint256 i = 0; i < extraRewardContracts.length; i++) {
            IBasicRewards(extraRewardContracts[i]).getReward(msg.sender);
        }
        //claim from multi reward token contract
        for (uint256 i = 0; i < tokenRewardContracts.length; i++) {
            IBasicRewards(tokenRewardContracts[i]).depositFor(tokenRewardPids[i], 0, msg.sender);
        }

        // claim others/deposit/lock/stake
        _claimExtras(depositWomMaxAmount, minAmountOut, depositWmxMaxAmount, womBalance, wmxBalance, options);
    }

    /**
     * @notice  Claim additional rewards from:
     *          - wmxWomRewards
     *          - wmxLocker
     * @param depositWomMaxAmount see claimRewards
     * @param minAmountOut        see claimRewards
     * @param depositWmxMaxAmount see claimRewards
     * @param removeWomBalance    womBalance to ignore and not redeposit (starting Wom balance)
     * @param removeWmxBalance    wmxBalance to ignore and not redeposit (starting Wmx balance)
     * @param options             see claimRewards
     */
    // prettier-ignore
    function _claimExtras( // solhint-disable-line
        uint256 depositWomMaxAmount,
        uint256 minAmountOut,
        uint256 depositWmxMaxAmount,
        uint256 removeWomBalance,
        uint256 removeWmxBalance,
        uint256 options
    ) internal {
        //claim from wmxWom rewards
        if (_checkOption(options, Options.ClaimWmxWom)) {
            IBasicRewards(wmxWomRewards).getReward(msg.sender, _checkOption(options, Options.LockWmxRewards));
        }

        //claim from locker
        if (_checkOption(options, Options.ClaimLockedWmx)) {
            IWmxLocker(locker).getReward(msg.sender, _checkOption(options, Options.ClaimLockedWmxStake));
        }

        //reset remove balances if we want to also stake/lock funds already in our wallet
        if (_checkOption(options, Options.UseAllWalletFunds)) {
            removeWomBalance = 0;
            removeWmxBalance = 0;
        }

        //lock upto given amount of wom and stake
        if (depositWomMaxAmount > 0) {
            uint256 womBalance = IERC20(wom).balanceOf(msg.sender).sub(removeWomBalance);
            womBalance = WmxMath.min(womBalance, depositWomMaxAmount);

            if (womBalance > 0) {
                //pull wom
                IERC20(wom).safeTransferFrom(msg.sender, address(this), womBalance);
                //deposit
                IWomDepositorWrapper(womDepositor).deposit(
                    womBalance,
                    minAmountOut,
                    _checkOption(options, Options.LockWomDeposit),
                    address(0)
                );

                uint256 wmxWomBalance = IERC20(womWmx).balanceOf(address(this));
                //stake for msg.sender
                IBasicRewards(wmxWomRewards).stakeFor(msg.sender, wmxWomBalance);
            }
        }

        //stake up to given amount of wmx
        if (depositWmxMaxAmount > 0 && _checkOption(options, Options.LockWmx)) {
            uint256 wmxBalance = IERC20(wmx).balanceOf(msg.sender).sub(removeWmxBalance);
            wmxBalance = WmxMath.min(wmxBalance, depositWmxMaxAmount);
            if (wmxBalance > 0) {
                //pull wmx
                IERC20(wmx).safeTransferFrom(msg.sender, address(this), wmxBalance);
                IWmxLocker(locker).lock(msg.sender, wmxBalance);
            }
        }
    }
}