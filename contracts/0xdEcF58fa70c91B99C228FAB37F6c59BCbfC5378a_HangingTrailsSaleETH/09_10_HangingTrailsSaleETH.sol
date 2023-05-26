// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Withdrawable} from "../utility/Withdrawable.sol";

contract HangingTrailsSaleETH is Ownable, Withdrawable {
    using SafeERC20 for IERC20;

    IERC20 public s_usdt;

    constructor() {
        if (block.chainid == 1) {
            s_usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        } else {
            s_usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        }
        _transferOwnership(0x6FA6DA462CBA635b0193809332387cDC25Df3e8D);
    }

    event BoughtWithNativeToken(address user, uint256 amount, uint256 time);
    event BoughtWithUSDT(address user, uint256 amount, uint256 time);

    function buyTokensNative() external payable {
        (bool sent, ) = payable(owner()).call{value: msg.value}("");
        require(sent, "Funds transfer unsuccesfull");
        emit BoughtWithNativeToken(msg.sender, msg.value, block.timestamp);
    }

    function buyTokensUSDT(uint256 amount) external {
        s_usdt.safeTransferFrom(msg.sender, owner(), amount);
        emit BoughtWithUSDT(msg.sender, amount, block.timestamp);
    }

    receive() external payable {}
}