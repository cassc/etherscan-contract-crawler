// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRewardVault} from "src/interfaces/IRewardVault.sol";

contract RewardVault is IRewardVault, Ownable {
    using SafeERC20 for IERC20;

    address public immutable rebornToken;

    constructor(address owner_, address rebornToken_) {
        if (rebornToken_ == address(0)) revert ZeroAddressSet();
        _transferOwnership(owner_);
        rebornToken = rebornToken_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function reward(
        address to,
        uint256 amount
    ) external virtual override onlyOwner {
        IERC20(rebornToken).safeTransfer(to, amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual override onlyOwner {
        if (to == address(0)) revert ZeroAddressSet();
        IERC20(rebornToken).safeTransfer(
            to,
            IERC20(rebornToken).balanceOf(address(this))
        );
        emit WithdrawEmergency(
            rebornToken,
            IERC20(rebornToken).balanceOf(address(this))
        );
    }
}