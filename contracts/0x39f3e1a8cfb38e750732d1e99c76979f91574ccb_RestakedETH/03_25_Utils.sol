// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Utils {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function payMe(address payer, uint256 amount, address token) internal returns (bool) {
        return payTo(payer, address(this), amount, token);
    }

    function payTo(address allower, address receiver, uint256 amount, address token) internal returns (bool) {
        // Request to transfer amount from the contract to receiver.
        // Contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        return IERC20(token).transferFrom(allower, receiver, amount);
    }

    function payDirect(address to, uint256 amount, address token) internal returns (bool) {
        IERC20(token).safeTransfer(to, amount);
        return true;
    }

    function contractExists(address contractAddress) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(contractAddress)
        }
        return size > 0;
    }
}