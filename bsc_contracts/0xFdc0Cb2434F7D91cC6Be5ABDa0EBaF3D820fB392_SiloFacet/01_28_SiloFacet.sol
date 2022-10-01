/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity = 0.8.16;

import "./TopcornSilo.sol";
import "../../../libraries/LibClaim.sol";
import "../../../libraries/LibMarket.sol";
import "../../../libraries/LibTopcornBnb.sol";

/**
 * @title Silo handles depositing and withdrawing Topcorns and LP, and updating the Silo.
 **/
contract SiloFacet is TopcornSilo {
    event TopcornAllocation(address indexed account, uint256 topcorns);

    /*
     * TopCorn
     */

    // Deposit
    
    function claimAndDepositTopcorns(uint256 amount, LibClaim.Claim calldata claim) external siloNonReentrant {
        allocateTopcorns(claim, amount);
        _depositTopcorns(amount);
        LibMarket.claimRefund(claim);
    }

    function claimBuyAndDepositTopcorns(
        uint256 amount,
        uint256 buyAmount,
        LibClaim.Claim calldata claim
    ) external payable siloNonReentrant {
        allocateTopcorns(claim, amount);
        uint256 boughtAmount = LibMarket.buyAndDeposit(buyAmount);
        _depositTopcorns(boughtAmount + amount);
    }

    function depositTopcorns(uint256 amount) external silo {
        topcorn().transferFrom(msg.sender, address(this), amount);
        _depositTopcorns(amount);
    }

    function buyAndDepositTopcorns(uint256 amount, uint256 buyAmount) external payable siloNonReentrant {
        uint256 boughtAmount = LibMarket.buyAndDeposit(buyAmount);
        if (amount > 0) topcorn().transferFrom(msg.sender, address(this), amount);
        _depositTopcorns(boughtAmount + amount);
    }

    // Withdraw

    function withdrawTopcorns(uint32[] calldata crates, uint256[] calldata amounts) external silo {
        _withdrawTopcorns(crates, amounts);
    }

    function claimAndWithdrawTopcorns(
        uint32[] calldata crates,
        uint256[] calldata amounts,
        LibClaim.Claim calldata claim
    ) external siloNonReentrant {
        LibClaim.claim(claim);
        _withdrawTopcorns(crates, amounts);
        LibMarket.claimRefund(claim);
    }

    /*
     * LP
     */

    function claimAndDepositLP(uint256 amount, LibClaim.Claim calldata claim) external siloNonReentrant {
        LibClaim.claim(claim);
        pair().transferFrom(msg.sender, address(this), amount);
        _depositLP(amount);
        LibMarket.claimRefund(claim);
    }

    function claimAddAndDepositLP(
        uint256 lp,
        uint256 buyTopcornAmount,
        uint256 buyBNBAmount,
        LibMarket.AddLiquidity calldata al,
        LibClaim.Claim calldata claim
    ) external payable siloNonReentrant {
        LibClaim.claim(claim);
        _addAndDepositLP(lp, buyTopcornAmount, buyBNBAmount, al);
    }

    function depositLP(uint256 amount) external siloNonReentrant {
        pair().transferFrom(msg.sender, address(this), amount);
        _depositLP(amount);
    }

    function addAndDepositLP(
        uint256 lp,
        uint256 buyTopcornAmount,
        uint256 buyBNBAmount,
        LibMarket.AddLiquidity calldata al
    ) external payable siloNonReentrant {
        require(buyTopcornAmount == 0 || buyBNBAmount == 0, "Silo: Silo: Cant buy BNB and Topcorns.");
        _addAndDepositLP(lp, buyTopcornAmount, buyBNBAmount, al);
    }

    function _addAndDepositLP(
        uint256 lp,
        uint256 buyTopcornAmount,
        uint256 buyBNBAmount,
        LibMarket.AddLiquidity calldata al
    ) internal {
        uint256 boughtLP = LibMarket.swapAndAddLiquidity(buyTopcornAmount, buyBNBAmount, al);
        if (lp > 0) pair().transferFrom(msg.sender, address(this), lp);
        _depositLP(lp + boughtLP);
        LibMarket.refund();
    }

    function lpToLPTopcorns(uint256 amount) external view returns (uint256) {
        return LibTopcornBnb.lpToLPTopcorns(amount);
    }
    
    /*
     * Withdraw
     */

    function claimAndWithdrawLP(
        uint32[] calldata crates,
        uint256[] calldata amounts,
        LibClaim.Claim calldata claim
    ) external siloNonReentrant {
        LibClaim.claim(claim);
        _withdrawLP(crates, amounts);
        LibMarket.claimRefund(claim);
    }

    function withdrawLP(uint32[] calldata crates, uint256[] calldata amounts) external silo {
        _withdrawLP(crates, amounts);
    }

    function allocateTopcorns(LibClaim.Claim calldata c, uint256 transferTopcorns) private {
        LibClaim.claim(c);
        LibMarket.allocateTopcorns(transferTopcorns);
    }
}