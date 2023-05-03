// Hark, ye mortals! This contract offers 1001 brave souls the opportunity to claim the coveted RG tokens. 
// The Reaper, ever eager to entice more players into his perilous contest, grants tokens to those who dare accept 
// his challenge and have not yet partaken in the game. A balance of nought is required for a mortal to claim 
// their share of 999 tokens, but caution is advised, for the Reaper is ever watchful.
//
// Once claimed, the RG tokens join their bearer in the dance of fate, as each seeks to survive the Reaper's 
// relentless pursuit. Those who hold the tokens shall face Death's wrath every 9 days, transferring their tokens 
// to a new address, lest they be locked away in his eternal grasp.
//
// Yet, remember, this game is not for the faint of heart or those seeking mere monetary gain. It is a testament 
// to the eternal struggle between life and the ever-looming spectre of Death, where participants strive to survive 
// and defy the Reaper's cold embrace.
//
// So, let it be known, those who choose to join this macabre game of chance, that the Reaper watches with keen interest, 
// and only time will reveal the true purpose of this enigmatic claim contract. Mayhap in the future, players may be rewarded, 
// regardless of their amassed fortunes, as Death's plan unfolds in his intricate, nefarious design.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RGclaim is Ownable {
    IERC20 public token;
    uint256 public constant CLAIM_AMOUNT = 9999 * 10**18;
    address public constant TOKEN_ADDRESS = 0x2C91D908E9fab2dD2441532a04182d791e590f2d;

    constructor() {
        token = IERC20(TOKEN_ADDRESS);
    }

    function DanceWithDeath() external {
        require(token.balanceOf(msg.sender) == 0, "You already have RG tokens");

        token.transfer(msg.sender, CLAIM_AMOUNT);
    }

    function depositTokens(uint256 amount) external onlyOwner {
        require(token.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdrawRemainingTokens(address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        uint256 remainingTokens = token.balanceOf(address(this));
        token.transfer(recipient, remainingTokens);
    }
}