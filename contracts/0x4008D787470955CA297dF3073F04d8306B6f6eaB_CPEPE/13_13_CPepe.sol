// bep20 token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CPEPE is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {
    using SafeMath for uint;

    uint256 private totalTokens;
    uint256 private percentAntiWhale = 0;
    uint256 private antiBotValue = 0;
    uint256 private launchTime = 0;
    uint256 private offTime = 0;

    constructor() ERC20("C PEPE", "CPEPE") {
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
    ) internal override(ERC20, ERC20Snapshot) {
        if (block.timestamp >= launchTime && block.timestamp <= offTime) {
            if (from != owner() || to != owner()) {
                require(
                    amount <= totalSupply().div(100).mul(percentAntiWhale),
                    "Anti Whale: Transfer exceeded the allowable value."
                );
                require(
                    address(to).balance > antiBotValue,
                    "Anti Bot: The recipient must have a token balance greater than 0."
                );
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function getBurnedAmountTotal() external view returns (uint256 _amount) {
        return totalTokens.sub(totalSupply());
    }

    function enableProtect(
        uint256 _percentAntiWhale,
        uint256 _valueAntiBot,
        uint256 _launchTime,
        uint256 _offTime
    ) external onlyOwner {
        require(launchTime == 0, "Anti Rug: Already enabled.");

        percentAntiWhale = _percentAntiWhale;
        antiBotValue = _valueAntiBot;
        launchTime = _launchTime;
        offTime = _offTime;
    }
}