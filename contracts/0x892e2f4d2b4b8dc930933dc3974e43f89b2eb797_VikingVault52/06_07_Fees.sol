// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Fees is Ownable {

    address internal creator = 0x0c051a1f4E209b00c8E7C00AD0ce79B3630a7401;
    address public feeAddress; // defaults to the Owner account.

    uint256 private creatorFee = 10;
    uint256 internal withdrawFeePeriod;
    uint256 internal withdrawPenaltyPeriod;
    uint256 internal withdrawFee;
 
    error ExitFeesFailed();
    
    event ExitWithFees(address indexed user, uint256 amount);

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
    function setFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
    }
    /// @notice Admin function to set a new withdraw fee.
    /// @notice example: 50 = 0.5%, 100 = 1%, 200 = 2%, 1000 = 10%.
    function setWithdrawFee(uint256 _newWithdrawFee) external onlyOwner {
        withdrawFee = _newWithdrawFee;
    }

    /// @notice Function returns the current withdraw fee.
    function getWithdrawFee() external view returns (uint256){
        return withdrawFee;
    }
}