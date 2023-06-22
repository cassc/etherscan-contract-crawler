// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./RejectEther.sol";
import "./NiftyPermissions.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";

abstract contract Withdrawable is RejectEther, NiftyPermissions {

    /**
     * @dev Slither identifies an issue with sending ETH to an arbitrary destianation.
     * https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
     * Recommended mitigation is to "Ensure that an arbitrary user cannot withdraw unauthorized funds."
     * This mitigation has been performed, as only the contract admin can call 'withdrawETH' and they should
     * verify the recipient should receive the ETH first.
     */
    function withdrawETH(address payable recipient, uint256 amount) external {
        _requireOnlyValidSender();
        require(amount > 0, ERROR_ZERO_ETH_TRANSFER);
        require(recipient != address(0), "Transfer to zero address");

        uint256 currentBalance = address(this).balance;
        require(amount <= currentBalance, ERROR_INSUFFICIENT_BALANCE);

        //slither-disable-next-line arbitrary-send        
        (bool success,) = recipient.call{value: amount}("");
        require(success, ERROR_WITHDRAW_UNSUCCESSFUL);
    }
        
    function withdrawERC20(address tokenContract, address recipient, uint256 amount) external {
        _requireOnlyValidSender();
        bool success = IERC20(tokenContract).transfer(recipient, amount);
        require(success, ERROR_WITHDRAW_UNSUCCESSFUL);
    }
    
    function withdrawERC721(address tokenContract, address recipient, uint256 tokenId) external {
        _requireOnlyValidSender();
        IERC721(tokenContract).safeTransferFrom(address(this), recipient, tokenId, "");
    }    
}