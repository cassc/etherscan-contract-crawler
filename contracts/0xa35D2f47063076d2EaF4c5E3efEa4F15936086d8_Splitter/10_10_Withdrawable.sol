// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/**
    Ensures that any contract that inherits from this contract is able to
    withdraw funds that are accidentally received or stuck.
 */

contract Withdrawable {
    using SafeERC20 for IERC20;
    address constant ETHER = address(0);

    event LogWithdraw(
        address indexed _from,
        address indexed _assetAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    /**
     * @notice Withdraw asset ERC20 or ETH
     * @param _assetAddress Asset to be withdrawn.
     */
    function withdrawERC20ETH(address _assetAddress) public virtual {
        uint256 assetBalance;
        if (_assetAddress == ETHER) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            payable(msg.sender).transfer(assetBalance);
        } else {
            assetBalance = IERC20(_assetAddress).balanceOf(address(this));
            IERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
        }
        emit LogWithdraw(msg.sender, _assetAddress, 0, assetBalance);
    }
}