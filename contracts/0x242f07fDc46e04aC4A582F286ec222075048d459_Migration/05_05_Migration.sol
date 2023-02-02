// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @title Migration: Contract for Migrating MRI tokens over to the MFC token
 */
contract Migration is Ownable, ReentrancyGuard {
    
    
    bool public isWithdrawEnabled;
    bool public isDepositEnabled;
    uint256 public swapRateMultiplier;
    uint256 public swapRateDivider;

    mapping (address => uint256) public migratedMRI;
    mapping (address => uint256) public totalMFCdue;
    mapping (address => uint256) public withdrawnMFC;

    IERC20 public MRI;
    IERC20 public MFC;
    
    

    event WithdrawnMRI(address indexed user, uint256 amount);
    event WithdrawnMFC(address indexed user, uint256 amount);
    event DepositedMRI(address indexed user, uint256 amount);
    event EmergencyWithdrawMFC(uint256 amount);
    event WithdrawsEnabled(bool status);
    event DepositEnabled(bool status);
    event SwapRateUpdated(uint256 swapRateMultiplier, uint256 swapRateDivider);
    event TokenSet(address tokenMRI, address tokenMFC);
    error WithdrawMFC_NotEnabled();
    error DepositedMRI_NotEnabled();
    error WithdrawMFC_NothingToWithdraw();

    constructor(address _MRI, uint256 _swapRateMultiplier, uint256 _swapRateDivider) {
        MRI =  IERC20(_MRI);
        swapRateMultiplier = _swapRateMultiplier; 
        swapRateDivider = _swapRateDivider;
    }

    /**
     * @dev deposit MRI tokens to get the MFC MFC tokens
     * @param _amount: Amount of MRI tokens to migrate
     */
    function depositMRI(uint256 _amount) external nonReentrant {
        if( !isDepositEnabled) {
            revert DepositedMRI_NotEnabled();
        }
        bool success = MRI.transferFrom(msg.sender, address(this), _amount);
        if( success){
            uint256 MFCAmount = _amount * swapRateMultiplier / swapRateDivider;
            migratedMRI[msg.sender] += _amount;
            totalMFCdue[msg.sender] += MFCAmount;
            emit DepositedMRI(msg.sender, _amount);
        }
        else {
            revert();
        }

    }
    /**
     * @dev Withdraws MFC tokens from the contract
     */
    function withdrawMFC() external nonReentrant {
        if( !isWithdrawEnabled) {
            revert WithdrawMFC_NotEnabled();
        } 
        uint256 withdrawAmount = totalMFCdue[msg.sender] - withdrawnMFC[msg.sender];
      
        if(  withdrawAmount == 0) {
            revert WithdrawMFC_NothingToWithdraw();
        }
        withdrawnMFC[msg.sender] += withdrawAmount;
        bool success = MFC.transfer(msg.sender, withdrawAmount);
        if(!success)
            revert();
        emit WithdrawnMFC(msg.sender, withdrawAmount);
    }

    /**
     * @dev Withdraws MRI tokens from the contract
     * @param percentage: Percentage of MRI tokens to withdraw
     */
    function withdrawMRI(uint256 percentage) external onlyOwner {
        bool success = MRI.transfer(msg.sender, MRI.balanceOf(address(this)) * percentage / 100);
        if(!success)
            revert();
        emit WithdrawnMRI(msg.sender, MRI.balanceOf(address(this)) * percentage / 100);
    }

    /**
     * @dev Owner Withdraws MFC tokens from the contract in case of emergency
     * @param percentage: Percentage of MFC tokens to withdraw
     */
    function emergencyWithdrawMFC(uint256 percentage) external onlyOwner {
        bool success = MFC.transfer(msg.sender, MFC.balanceOf(address(this)) * percentage / 100);
        if(!success)
            revert();
        emit EmergencyWithdrawMFC(MFC.balanceOf(address(this)) * percentage / 100);
    }

    /**
     * @dev Enable withdraws
     * param status: Boolean to enable or disable withdraws
     */
    function enableWithdraws(bool status) external onlyOwner {
        isWithdrawEnabled = status;
        emit WithdrawsEnabled(status);
    }
    /**
     * @dev Enable deposits
     * param status: Boolean to enable or disable deposits
     */
    function enableDeposits(bool status) external onlyOwner {
        isDepositEnabled = status;
        emit DepositEnabled(status);
    }

    /**
    
     */

    /**
     * @dev Sets the swap rate for the migration (therefore: 0 < swapRate < 1 or swapRate > 1 )
     * @param _swapRateMultiplier: Multiplier to calculate the token migration rate
     * @param _swapRateDivider: Divider to calculate the token migration rate 
     */
    function setSwapRate(uint256 _swapRateMultiplier, uint256 _swapRateDivider) external onlyOwner {
        if( _swapRateMultiplier == 0 || _swapRateDivider == 0)
            revert();
        swapRateMultiplier = _swapRateMultiplier;
        swapRateDivider = _swapRateDivider;
        emit SwapRateUpdated(_swapRateMultiplier, _swapRateDivider);
    }

    /**
     * @dev Sets the start time for the migration
     * @param _MRI: Address of the MRI token
     * @param _MFC: Address of the MFC token
     */
    function setTokens(address _MRI, address _MFC) external onlyOwner {
        MRI = IERC20(_MRI);
        MFC = IERC20(_MFC);
        emit TokenSet(_MRI, _MFC);
    }

    /**
     * @dev Returns the amount of MFC tokens that can be withdrawn by the user
     */
    function getWithdrawableTokens(address _user) external view returns(uint256 withdrawableTokens) {
        return totalMFCdue[_user] - withdrawnMFC[_user];
    }

}