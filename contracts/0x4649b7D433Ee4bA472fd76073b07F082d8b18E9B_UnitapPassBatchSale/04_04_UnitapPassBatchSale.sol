// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUnitapPass.sol";

contract UnitapPassBatchSale is Ownable {
    uint32 public constant MAX_SALE_COUNT = 2000;

    address public unitapPass;
    address public safe; // all funds will be withdrawn to this address

    uint32 public totalSoldCount;
    uint32 public batchSize;
    uint32 public batchSoldCount;
    uint256 public price;

    constructor(
        address unitapPass_,
        address safe_,
        uint256 price_
    ) Ownable() {
        unitapPass = unitapPass_;
        safe = safe_;
        price = price_;
    }

    event StartBatch(uint32 batchSize);
    event MultiMint(address to, uint32 count);
    event WithdrawETH(uint256 amount, address to);

    error InvalidBatchSize();
    error CurrentBatchSoldOut();
    error InsufficientFunds();

    function startBatch(uint32 batchSize_) external onlyOwner {
        if (totalSoldCount + batchSize_ > MAX_SALE_COUNT) {
            revert InvalidBatchSize();
        }

        batchSize = batchSize_;
        batchSoldCount = 0;

        emit StartBatch(batchSize);
    }

    function multiMint(uint32 count, address to) external payable {
        if (batchSoldCount + count > batchSize) revert CurrentBatchSoldOut();

        uint256 totalValue = price * count;

        if (msg.value < totalValue) revert InsufficientFunds();

        for (uint32 i = 0; i < count; i++) {
            IUnitapPass(unitapPass).safeMint(to);
        }

        batchSoldCount += count;
        totalSoldCount += count;

        // refund extra ETH
        if (msg.value > totalValue) {
            payable(msg.sender).transfer(msg.value - totalValue);
        }

        emit MultiMint(to, count);
    }

    function withdrawETH() external {
        uint256 amount = address(this).balance;
        payable(safe).transfer(amount);
        emit WithdrawETH(amount, safe);
    }
}