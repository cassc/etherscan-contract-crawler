// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

error ZeroAddressError();

contract ERC20PairFee is Ownable {
    address public feeReceiver;
    mapping(address => bool) public isPair;
    uint32 public buyFeeBps;
    uint32 public sellFeeBps;

    constructor(address owner) {
        feeReceiver = owner;
    }

    function setPair(address pair, bool status) external onlyOwner {
        if (status == false) {
            delete isPair[pair];
            return;
        }
        isPair[pair] = status;
    }

    function setFeeReceiver(address receiver) external onlyOwner {
        if (receiver == address(0)) revert ZeroAddressError();
        feeReceiver = receiver;
    }

    function setFee(uint32 buyFee, uint32 sellFee) external onlyOwner {
        buyFeeBps = buyFee;
        sellFeeBps = sellFee;
    }

    function calculateFee(
        address from,
        address to,
        uint256 amount
    ) internal view returns (uint256, uint256) {
        uint256 fee = 0;
        if (isPair[from]) {
            fee = amount * buyFeeBps / 10_000;
            amount -= fee;
        } else if (isPair[to]) {
            fee = amount * sellFeeBps / 10_000;
            amount -= fee;
        }

        return (amount, fee);
    }
}