// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IClaimableFunds.sol";
import "./Guard.sol";

abstract contract Claimable is Guard, ReentrancyGuard, IClaimableFunds {
    /**
    @notice Returns the amount of funds available to claim
    @param asset_ Asset to withdraw, 0x0 - is native coin (eth)
    */
    function availableToClaim(
        address, /*owner_*/
        address asset_
    ) external view returns (uint256) {
        if (asset_ == address(0x0)) {
            return address(this).balance;
        } else {
            return IERC20(asset_).balanceOf(address(this));
        }
    }

    /**
    @notice Claim funds
    @param asset_ Asset to withdraw, 0x0 - is native coin (eth)
    @param target_ The target for the withdrawal 
    @param amount_ The amount of 
    */
    function claimFunds(
        address asset_,
        address payable target_,
        uint256 amount_
    ) external haveRights nonReentrant {
        require(target_ != address(0), "ZERO ADDRESS");
        if (asset_ == address(0x0)) {
            (bool sent, ) = target_.call{value: amount_}("");
            require(sent, "Can't sent");
        } else {
            require(
                IERC20(asset_).transfer(target_, amount_),
                "CANNOT TRANSFER"
            );
        }
    }
}