//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/auth/Ownable.sol";

contract Managed is Ownable {
    // Withdraw ETH from this contract
    function withdrawETH(uint256 _amount) public onlyOwner {
        SafeTransferLib.forceSafeTransferETH(owner(), _amount == 0 ? address(this).balance : _amount);
    }

    // Withdraw ERC20 token from this contract
    function withdrawToken(address _token, uint256 _amount) public onlyOwner {
        if(_amount == 0) SafeTransferLib.safeTransferAll(_token,  owner());
        else SafeTransferLib.safeTransfer(_token, owner(), _amount);
    }
}