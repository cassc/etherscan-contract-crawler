// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IHarvesttablePoolHelper.sol";
import "../interfaces/wombat/IWombatStaking.sol";
import "../interfaces/wombat/IMasterWombat.sol";
import "../interfaces/IMasterMagpie.sol";
import "../interfaces/IMintableERC20.sol";
import "../interfaces/IWNative.sol";

/// @title WombatPoolHelper
/// @author Magpie Team
/// @notice This contract is the main contract that user will intreact with in order to stake stable in Wombat Pool

contract WombatPoolHelper is IHarvesttablePoolHelper {
    using SafeERC20 for IERC20;

    /* ============ Constants ============ */

    address public immutable depositToken; // token to deposit into wombat
    address public immutable lpToken;      // lp token receive from wombat, also the pool identified on womabtStaking
    address public immutable stakingToken; // token staking to master magpie
    address public immutable mWom;
    
    address public immutable masterMagpie;
    address public immutable wombatStaking; 
    address public immutable rewarder; 

    uint256 public immutable pid; // pid on master wombat

    bool public immutable isNative;

    /* ============ Events ============ */

    event NewDeposit(address indexed _user, uint256 _amount);
    event NewLpDeposit(address indexed _user, uint256 _amount);
    event NewWithdraw(address indexed _user, uint256 _amount);

    /* ============ Errors ============ */

    error NotNativeToken();

    /* ============ Constructor ============ */

    constructor(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _lpToken,
        address _wombatStaking,
        address _masterMagpie,
        address _rewarder,
        address _mWom,
        bool _isNative
    ) {
        pid = _pid;
        stakingToken = _stakingToken;
        depositToken = _depositToken;
        lpToken = _lpToken;
        wombatStaking = _wombatStaking;
        masterMagpie = _masterMagpie;
        rewarder = _rewarder;
        mWom = _mWom;
        isNative = _isNative;
    }

    /* ============ External Getters ============ */

    /// notice get the amount of total staked LP token in master magpie
    function totalStaked() external override view returns (uint256) {
        return IBaseRewardPool(rewarder).totalStaked();
    }
    
    /// @notice get the total amount of shares of a user
    /// @param _address the user
    /// @return the amount of shares
    function balance(address _address) external override view returns (uint256) {
        return IBaseRewardPool(rewarder).balanceOf(_address);
    }

    /// @notice returns the number of pending MGP of the contract for the given pool
    /// returns pendingTokens the number of pending MGP
    function pendingWom() external view returns (uint256 pendingTokens) {
        (pendingTokens, , , ) = IMasterWombat(
            IWombatStaking(wombatStaking).masterWombat()
        ).pendingTokens(pid, wombatStaking);
    }    


    /* ============ External Functions ============ */
    
    /// @notice deposit stables in wombat pool, autostake in master magpie    
    /// @param _amount the amount of stables to deposit
    function deposit(uint256 _amount, uint256 _minimumLiquidity) external override {
        _deposit(_amount, _minimumLiquidity, msg.sender);
    }

    function depositLP(uint256 _lpAmount) external {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IWombatStaking(wombatStaking).depositLP(lpToken, _lpAmount, msg.sender);
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, msg.sender);
        
        emit NewLpDeposit(msg.sender, _lpAmount);
    }

    function depositNative(uint256 _minimumLiquidity) external payable {
        if(!isNative) revert NotNativeToken();
        // Dose need to limit the amount must > 0?

        // Swap the BNB to wBNB
        _wrapNative();
        // depsoit wBNB to the pool
        IWNative(depositToken).approve(wombatStaking, msg.value);
        _deposit(msg.value, _minimumLiquidity, address(this));
        IWNative(depositToken).approve(wombatStaking, 0);
    }

    /// @notice withdraw stables from wombat pool, auto unstake from master Magpie
    /// @param _liquidity the amount of liquidity to withdraw
    function withdraw(uint256 _liquidity, uint256 _minAmount) external override {
        // we have to withdraw from wombat exchange to harvest reward to base rewarder
        IWombatStaking(wombatStaking).withdraw(
            lpToken,
            _liquidity,
            _minAmount,
            msg.sender
        );
        // then we unstake from master wombat to trigger reward distribution from basereward
        _unstake(_liquidity, msg.sender);
        //  last burn the staking token withdrawn from Master Magpie
        IWombatStaking(wombatStaking).burnReceiptToken(lpToken, _liquidity);


        emit NewWithdraw(msg.sender, _liquidity);
    }

    function harvest() external override {
        IWombatStaking(wombatStaking).harvest(lpToken);
    }

    /* ============ Internal Functions ============ */

    function _deposit(uint256 _amount, uint256 _minimumLiquidity, address _from) internal {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IWombatStaking(wombatStaking).deposit(lpToken, _amount, _minimumLiquidity, msg.sender, _from);
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, msg.sender);
        
        emit NewDeposit(msg.sender, _amount);
    }

    function _wrapNative() internal {
        IWNative(depositToken).deposit{value: msg.value}();
    }

    /// @notice stake the receipt token in the masterchief of GMP on behalf of the caller
    function _stake(uint256 _amount, address _sender) internal {
        IERC20(stakingToken).safeApprove(masterMagpie, _amount);
        IMasterMagpie(masterMagpie).depositFor(stakingToken, _amount, _sender);
    }

    /// @notice unstake from the masterchief of GMP on behalf of the caller
    function _unstake(uint256 _amount, address _sender) internal {
        IMasterMagpie(masterMagpie).withdrawFor(stakingToken, _amount, _sender);
    }
}