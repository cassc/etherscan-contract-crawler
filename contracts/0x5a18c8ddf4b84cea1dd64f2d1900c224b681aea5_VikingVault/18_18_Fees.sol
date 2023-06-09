// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Admin.sol";
import "./Events.sol";  

contract Fees is Admin, Events {

    address public feeAddress; // defaults to the Owner account.

    uint256 internal creatorFee = 300;
    uint256 internal withdrawFeePeriod;
    uint256 internal withdrawPenaltyPeriod;
    uint256 internal withdrawFee = 1000;
 
    error ExitFeesFailed();
    
    /// @notice Internal function to calculate the early withdraw fees.
    /// @notice return contarctAmount, feeAmount and withdrawAmount.
    function _calculateFee(uint256 _amount) 
        internal 
        view 
        returns (
            uint256 contractAmount,
            uint256 feeAmount,
            uint256 withdrawAmount
        ) 
    {
        uint256 totFee = _amount * withdrawFee / 10000;
        
        contractAmount = totFee * creatorFee /10000;
        feeAmount = totFee - contractAmount;
        withdrawAmount = _amount - totFee; 
    }

    /// @notice Admin function to set a new fee address.
    function setFeeAddress(address _newFeeAddress) external onlyRole(ADMIN_ROLE) {
        feeAddress = _newFeeAddress;
    }
    /// @notice Admin function to set a new withdraw fee.
    /// @notice example: 50 = 0.5%, 100 = 1%, 200 = 2%, 1000 = 10%.
    function setWithdrawFee(uint256 _newWithdrawFee) external onlyRole(ADMIN_ROLE) {
        withdrawFee = _newWithdrawFee;
    }

    /// @notice Function returns the current withdraw fee.
    function getWithdrawFee() external view returns (uint256){
        return withdrawFee;
    }
}