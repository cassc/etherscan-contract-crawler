// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnerWithdrawable is Ownable {

    receive() external payable {}

    fallback() external payable {}

    /// @notice Owner can call this function to withdraw BNB
    /// @param _amt Amount that needs to be withdrawn
    function withdrawCurrency(uint256 _amt) external onlyOwner {
        payable(msg.sender).transfer(_amt);
    }
    /// @notice Get the BNB balance of the presale contract
    /// @return Amount of BNB in wei
    function getCurrencyBalance() external view returns(uint256){
        return (address(this).balance);
    }

}