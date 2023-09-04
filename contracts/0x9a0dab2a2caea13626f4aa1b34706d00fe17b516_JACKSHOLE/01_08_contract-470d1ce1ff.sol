// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract JACKSHOLE is ERC20, ERC20Burnable, Pausable, Ownable {

    address public devWallet = 0xa83551179d2d559a015245307d0A12e9Df922EF6;

    uint256 public buyFee = 3;
    uint256 public sellFee = 3;
    uint256 public feeDenominator = 100;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) public isLiquidityPool;

    bool private tradingOpen = false;

    constructor() ERC20("JACKSON'S HOLE", "JACKSHOLE") {
        _mint(msg.sender, 33333333 * 10 ** decimals());
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
    }

function takeFee(address sender, uint256 amount, bool isSell) internal returns (uint256) {
        
    uint256 feeToTake = isSell ? sellFee : buyFee;
    uint256 feeAmount = (amount * feeToTake) / feeDenominator;

    super._transfer(sender, address(this), feeAmount);  // Accumulate fee within the contract

    return amount - feeAmount;
}



function withdrawFees(uint256 amount) external onlyOwner {
    require(amount <= balanceOf(address(this)), "Amount exceeds available fees in the contract");
    super._transfer(address(this), devWallet, amount);
}



function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(tradingOpen, "Trading is not yet open.");
        
        bool isSell = isLiquidityPool[recipient];
        bool isBuy = isLiquidityPool[sender];

        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            if (isSell) {
                amount = takeFee(sender, amount, true);
            } else if (isBuy) {
                amount = takeFee(sender, amount, false);
            }
        }
        super._transfer(sender, recipient, amount);
    }

    function setLiquidityPool(address poolAddress, bool value) external onlyOwner {
        isLiquidityPool[poolAddress] = value;
    }

    function setSwapFees(uint256 _newBuyFee, uint256 _newSellFee, uint256 _feeDenominator) external onlyOwner() {
        require( _newBuyFee + _newSellFee < feeDenominator, "Total fees cannot be more than 100%");
        
        buyFee = _newBuyFee;
        sellFee = _newSellFee;
        feeDenominator = _feeDenominator;
    }

    function setTreasuryFeeReceiver(address _newWallet) external onlyOwner() {
        devWallet = _newWallet;
    }
}