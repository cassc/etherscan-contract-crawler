// bep20 token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GiraffeClub is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {
    using SafeMath for uint;

    uint256 private totalTokens;
    uint256 public startTime;
    uint256 public endTime;
    uint256 private valueAntiBot;

    bool private isAntiBotEnabled = false;

    IERC20 private trackToken;

    constructor() ERC20("Giraffe Club", "GIRA") {
        startTime = block.timestamp;
        totalTokens = 1000000 * 10 ** 6 * 10 ** uint256(decimals()); // 1000B
        _mint(owner(), totalTokens);
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) _antiBot(from, to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function getBurnedAmountTotal() external view returns (uint256 _amount) {
        return totalTokens.sub(totalSupply());
    }

    /*
     * @dev Enable anti bot
     * @param _valueAntiBot: The recipient must have a token balance greater than _valueAntiBot.
     * @param _startTime: The time to start anti bot.
     * @param _endTime: The time to end anti bot.
     * @param _trackToken: The token to track.
     */
    function launchToTheMoon(
        address _trackToken,
        uint256 _endTime,
        uint256 _valueAntiBot
    ) external onlyOwner {
        require(isAntiBotEnabled == false, "Anti Bot: Already enabled.");
        // set anti bot value, start time, end time, track token and to the moon
        // this function can only be called once

        trackToken = IERC20(_trackToken);
        endTime = _endTime;
        valueAntiBot = _valueAntiBot;
        isAntiBotEnabled = true;
    }

    /*
     * @dev Anti bot modifier after launch
     * @param from: The sender address.
     * @param to: The recipient address.
     */
    modifier _antiBot(address from, address to) {
        // ignore pair and owner to token transactions
        if (from == owner() || to == owner() || tx.origin == owner()) {
            _;
        } else {
            if (block.timestamp > startTime && block.timestamp < endTime) {
                uint256 balanceAntiBot = trackToken.balanceOf(tx.origin);
                require(balanceAntiBot >= valueAntiBot);
            }
            _;
        }
    }
}