// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { PawnBots } from "./PawnBots.sol";
import { PB_BurnToken } from "./PB_BurnToken.sol";

error BurnTokenDistributor__NewRateMustBeLower();
error BurnTokenDistributor__InvalidInput();

contract BurnTokenDistributor is Ownable, ReentrancyGuard {
    event BurnBalance(uint256 burnAmount);
    event DecreaseRate(uint256 newRate);
    event Distribute(address indexed caller, uint256 amountIn, uint256 amountOut);
    event UpdatePawnBots(address newBots);

    address public constant BURN_TOKEN = 0xDeadb071ab55db23Aea4cF9b316faa8B7Bd26196;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public bots = 0x28F0521c77923F107E29a5502a5a1152517F9000;
    uint256 public rate = 1e18;

    function burnBalance(uint256 burnAmount) external onlyOwner {
        if (burnAmount == 0) {
            revert BurnTokenDistributor__InvalidInput();
        }

        PB_BurnToken(BURN_TOKEN).burn(burnAmount);
        emit BurnBalance(burnAmount);
    }

    function decreaseRate(uint256 newRate) external onlyOwner {
        if (newRate == 0) {
            revert BurnTokenDistributor__InvalidInput();
        }
        if (newRate >= rate) {
            revert BurnTokenDistributor__NewRateMustBeLower();
        }

        rate = newRate;
        emit DecreaseRate(newRate);
    }

    function distribute(uint256[] calldata inIds) external nonReentrant {
        if (inIds.length == 0) {
            revert BurnTokenDistributor__InvalidInput();
        }

        for (uint256 i; i < inIds.length; ) {
            PawnBots(bots).transferFrom(msg.sender, DEAD_ADDRESS, inIds[i]);
            unchecked {
                i++;
            }
        }

        uint256 amountOut;
        unchecked {
            amountOut = inIds.length * rate;
        }

        PB_BurnToken(BURN_TOKEN).transfer(msg.sender, amountOut);
        emit Distribute(msg.sender, inIds.length, amountOut);
    }

    function updatePawnBots(address newBots) external onlyOwner {
        if (newBots == address(0)) {
            revert BurnTokenDistributor__InvalidInput();
        }

        bots = newBots;
        emit UpdatePawnBots(newBots);
    }
}