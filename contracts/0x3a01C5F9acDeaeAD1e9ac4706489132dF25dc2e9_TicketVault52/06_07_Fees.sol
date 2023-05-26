// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Fees is Ownable {

    address public feeAddress; // deafult Owner account.
    uint256 internal withdrawFeePeriod; // default 3 months.
    uint256 internal withdrawPenaltyPeriod; // default 14 days.
    uint256 internal withdrawFee; // default 7%.

    error ExitFeesFailed();

    event ExitWithFees(address indexed user, uint256 amount, uint256 fees);

    /// @notice Internal function to calculate the early withdraw fees.
    /// @notice return feeAmount and withdrawAmount.
    function _calculateFee(uint256 _amount) 
        internal 
        view 
        returns (
            uint256 feeAmount, 
            uint256 withdrawAmount
        ) 
    {
        feeAmount = _amount * withdrawFee / 10000;
        withdrawAmount = _amount - feeAmount; 
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