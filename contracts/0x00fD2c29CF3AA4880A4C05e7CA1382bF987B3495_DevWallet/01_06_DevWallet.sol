// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/** 
 * @title DevWallet 
 * @author RobAnon
 */
contract DevWallet is Ownable {

    using SafeERC20 for IERC20;

    /**
     * @notice handle the forwarding of all contained ERC-20s to the recipient address
     * @param tokens the list of tokens to be forwarded
     * @param recipient the address to send those tokens to
     */
    function forwardERC20s(address[] memory tokens, address recipient) external onlyOwner {
        uint length = tokens.length;
        for(uint i = 0; i < length; ++i) {
            address token = tokens[i];
            uint balance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(recipient, balance);
        }
    }

    /**
     * @notice handles the withdrawal of any ether that has wandered into this contract
     * @param recipient the address to send the Ether to
     */
    function withdrawBalance(address payable recipient) external onlyOwner {
        uint balance = address(this).balance;
        recipient.transfer(balance);
    }

}