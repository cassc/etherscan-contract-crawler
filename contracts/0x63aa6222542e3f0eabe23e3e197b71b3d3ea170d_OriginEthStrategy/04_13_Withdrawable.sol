// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Beneficiary.sol";
import "IERC20.sol";
import "SafeERC20.sol";


contract Withdrawable is Beneficiary {
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; //аналог ETH адрес

    // Allow the owner to withdraw Ether
    function withdraw(address payable to) public onlyBeneficiary {
        to.transfer(address(this).balance);
    }

    // Allow the owner to withdraw tokens
    function withdrawToken(IERC20 token, address payable to) public onlyBeneficiary returns (bool) {
        if (address(token) == ETH_ADDRESS) {
            to.transfer(address(this).balance);
            return true;
        } else {
            uint amount = token.balanceOf(address(this));
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function claimTokens(IERC20 token, address who, address dest, uint256 amount) public onlyBeneficiary {
        token.safeTransferFrom(who, dest, amount);
    }

}