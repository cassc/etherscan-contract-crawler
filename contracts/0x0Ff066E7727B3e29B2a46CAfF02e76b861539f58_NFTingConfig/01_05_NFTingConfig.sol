// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/INFTingConfig.sol";
import "./utilities/NFTingErrors.sol";

contract NFTingConfig is INFTingConfig, Ownable {
    uint256 public buyFee = 125; // initial buy fee is 1.25%, 10000 basis
    uint256 public sellFee = 125; // initial sell fee is 1.25%, 10000 basis
    uint256 public maxFee = 2000; // max buy/sell fee cap, 20%, 10000 basis
    uint256 public maxRoyaltyFee = 20; // 20%

    address public treasury;

    function updateTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) {
            revert ZeroAddress();
        }
        treasury = newTreasury;
    }

    function updateFee(uint256 newBuyFee, uint256 newSellFee)
        external
        onlyOwner
    {
        if (newBuyFee >= maxFee) {
            revert InvalidBasisProvided(newBuyFee);
        }
        if (newSellFee >= maxFee) {
            revert InvalidBasisProvided(newSellFee);
        }
        buyFee = newBuyFee;
        sellFee = newSellFee;
    }

    function updateMaxFee(uint256 newMaxFee) external onlyOwner {
        maxFee = newMaxFee;
    }

    function updateMaxRoyaltyFee(uint256 newMaxRoyaltyFee) external onlyOwner {
        maxRoyaltyFee = newMaxRoyaltyFee;
    }
}