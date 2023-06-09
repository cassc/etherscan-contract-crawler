// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "./GenArtLoyaltyVault.sol";

/**
 * @dev Implements rebates and loyalties for GEN.ART members
 */
abstract contract GenArtLoyalty is GenArtAccess {
    uint256 constant DOMINATOR = 1000;
    uint256 public baseRebateBps = 125;
    uint256 public loyaltyRewardBps = 0;
    uint256 public rebateWindowSec = 60 * 60 * 24 * 5; // 5 days
    uint256 public loyaltyDistributionBlocks = 260 * 24 * 30; // 30 days
    uint256 public distributionDelayBlock = 260 * 24 * 14; // 14 days
    uint256 public lastDistributionBlock;

    GenArtLoyaltyVault public genartVault;

    constructor(address genartVault_) {
        genartVault = GenArtLoyaltyVault(payable(genartVault_));
    }

    /**
     * @dev Public method to send funds to {GenArtLoyaltyVault} for distribution
     */
    function distributeLoyalties() public {
        require(
            lastDistributionBlock == 0 ||
                block.number >= lastDistributionBlock + distributionDelayBlock,
            "distribution delayed"
        );
        uint256 balance = address(this).balance;
        require(balance > 0, "zero balance");
        genartVault.updateRewards{value: balance}(loyaltyDistributionBlocks);
        lastDistributionBlock = block.number;
    }

    /**
     * @dev Set the {GenArtLoyaltyVault} contract address
     */
    function setGenartVault(address genartVault_) external onlyAdmin {
        genartVault = GenArtLoyaltyVault(payable(genartVault_));
    }

    /**
     * @dev Set the base rebate bps per mint {e.g 125}
     */
    function setBaseRebateBps(uint256 bps) external onlyAdmin {
        baseRebateBps = bps;
    }

    /**
     * @dev Set the loyalty reward bps per mint {e.g 25}
     */
    function setLoyaltyRewardBps(uint256 bps) external onlyAdmin {
        loyaltyRewardBps = bps;
    }

    /**
     * @dev Set the rebate window
     */
    function setRebateWindow(uint256 rebateWindowSec_) external onlyAdmin {
        rebateWindowSec = rebateWindowSec_;
    }

    /**
     * @dev Set the block range for loyalty distribution
     */
    function setLoyaltyDistributionBlocks(uint256 blocks) external onlyAdmin {
        loyaltyDistributionBlocks = blocks;
    }

    /**
     * @dev Set the delay loyalty distribution (in blocks)
     */
    function setDistributionDelayBlock(uint256 blocks) external onlyAdmin {
        distributionDelayBlock = blocks;
    }

    receive() external payable {}
}