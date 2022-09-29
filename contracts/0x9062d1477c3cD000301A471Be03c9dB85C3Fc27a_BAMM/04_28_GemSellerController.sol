// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./../Dependencies/IERC20.sol";
import "./../Dependencies/Ownable.sol";

contract GemSellerController is Ownable {
    address public pendingGemSeller;
    uint    public pendingGemSellerUpdateTime;

    address public gemSeller;

    IERC20 public immutable gem;
    uint   public immutable timelockDuration;

    event GemSellerSet(address seller);
    event PendingGemSellerSet(address pendingSeller, uint time);    


    constructor(address _gem, uint _timelockDuration) public {
        gem = IERC20(_gem);
        timelockDuration = _timelockDuration;
    }

    function setSeller(address _seller) external onlyOwner {
        require(_seller != address(0x0), "setSeller: 0 address");

        // if not first init, then apply timelock
        if(gemSeller != address(0)) {
            require(now >= pendingGemSellerUpdateTime + timelockDuration, "setSeller: too early");            
            require(pendingGemSeller == _seller, "setSeller: ! pending");

            // reset prev seller
            require(gem.approve(gemSeller, 0), "setSeller: 0 allowance failed");
        }

        require(gem.approve(_seller, uint(-1)), "setSeller: gem allowance failed");
        gemSeller = _seller;

        // at this point owner can keep calling setSeller over and over without a timelock
        // but cannot change owner, so it is fine

        emit GemSellerSet(_seller);
    }

    function setPendingSeller(address _pendingSeller) external onlyOwner {
        pendingGemSeller = _pendingSeller;
        pendingGemSellerUpdateTime = now;

        emit PendingGemSellerSet(_pendingSeller, now);
    }
}