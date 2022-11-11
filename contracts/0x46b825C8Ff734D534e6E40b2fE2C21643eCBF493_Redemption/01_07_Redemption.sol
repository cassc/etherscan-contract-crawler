// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../openzeppelin/Ownable.sol";
import "../openzeppelin/ERC20.sol";
import "../openzeppelin/ReentrancyGuard.sol";

contract Redemption is Ownable, ReentrancyGuard {

    event BdammRedemption(
        address indexed from,
        uint256 amount,
        uint256 redemptionFee
    );
    event RedemptionUSDCPriceUpdated(
        uint256 oldPrice,
        uint256 newPrice
    );

    ERC20 BDAMM;
    ERC20 DAMM;
    ERC20 USDC;

    address public treasury;
    uint256 public redemptionUSDCPrice;
    uint256 public totalRedemptions;
    uint256 public totalUSDCFees;

    constructor(
        ERC20 addressBDAMM,      // 0xfa372fF1547fa1a283B5112a4685F1358CE5574d
        ERC20 addressDAMM,       // 0xb3207935FF56120f3499e8aD08461Dd403bF16b8
        ERC20 addressUSDC,       // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        address addressOwner,    // multisig address
        address addressTreasury, 
        uint256 _redemptionUSDCPrice
    ) {
        BDAMM = addressBDAMM;
        DAMM = addressDAMM;
        USDC = addressUSDC;
        Ownable._transferOwnership(addressOwner);
        treasury = addressTreasury;
        _updateRedemptionUSDCPrice(_redemptionUSDCPrice);
    }

    function _updateRedemptionUSDCPrice(uint256 _redemptionUSDCPrice) internal {
        emit RedemptionUSDCPriceUpdated(redemptionUSDCPrice, _redemptionUSDCPrice);
        redemptionUSDCPrice = _redemptionUSDCPrice;
    }
    /* 
      amount is the amount of BDAMM to swap to DAMM 1:1 (18 decimals)
      redemptionFee is the amount of USDC to send with the redemption (6 decimals)
    */
    function redeem(uint256 amount, uint256 redemptionFee) nonReentrant external {
        address user = msg.sender;
        uint256 allowanceBDAMM = BDAMM.allowance(user, address(this));
        require(amount <= allowanceBDAMM, "User has not given swap contract spend approval for BDAMM");
        uint256 requiredRedemptionFee = amount * redemptionUSDCPrice;
        require(redemptionFee * 1e18 == requiredRedemptionFee, "Incorrect USDC redemption fee sent");
        uint256 allowanceUSDC = USDC.allowance(user, address(this));
        require(redemptionFee <= allowanceUSDC, "User has not given swap contract spend approval for USDC");
        uint256 selfBalanceDAMM = DAMM.balanceOf(address(this));
        require(amount <= selfBalanceDAMM, "Not enough DAMM liquidity");
        totalUSDCFees += redemptionFee;
        totalRedemptions += amount;
        emit BdammRedemption(user, amount, redemptionFee);
        require(BDAMM.transferFrom(user, treasury, amount), "Could not transfer user's BDAMM to treasury");
        require(USDC.transferFrom(user, treasury, redemptionFee), "Could not transfer user's USDC to treasury");
        require(DAMM.transfer(user, amount), "Swap contract could not transfer DAMM to user");
    }

    function withdrawDAMM() onlyOwner external {
        uint256 balance = DAMM.balanceOf(address(this));
        require(DAMM.transfer(this.owner(), balance), "Admin could not withdraw DAMM");
    }

    function sweepToken(ERC20 token) onlyOwner external {
      uint256 balance = token.balanceOf(address(this));
      require(token.transfer(this.owner(), balance), "Admin could not withdraw token");
    }

    function updateRedemptionUSDCPrice(uint256 _redemptionUSDCPrice) onlyOwner external {
      _updateRedemptionUSDCPrice(_redemptionUSDCPrice);
    }

    function renounceOwnership() override public virtual onlyOwner {
        revert("Owner cannot renounce ownership");
    }

    function transferOwnership(address newOwner) override public virtual onlyOwner {
        // unused:
        newOwner;
        revert("Owner cannot transfer ownership");
    }
}