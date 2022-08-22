//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CreamFake is ERC20 {
    using SafeERC20 for IERC20;

    uint256 gains;
    address underlying;
    address rewardToken;
    bool loss;

    constructor(
        address _underlying,
        address _rewardToken,
        uint256 _gains,
        bool _loss
    ) public ERC20("", "") {
        underlying = _underlying;
        rewardToken = _rewardToken;
        gains = _gains;
        loss = _loss;
    }

    function mint(uint256 amount) public returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        return amount;
    }

    function redeem(uint256 redeemTokens) public returns (uint256) {
        uint256 factor = loss ? (100 - gains) : (100 + gains);
        uint256 amount = (redeemTokens * factor) / 100;
        IERC20(underlying).safeTransfer(msg.sender, amount);
        if (rewardToken != address(0)) {
            IERC20(rewardToken).safeTransfer(msg.sender, amount);
        }
        _burn(msg.sender, redeemTokens);
        return amount;
    }
}