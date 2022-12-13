// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Rebased Airdrop Contract
 */
contract BEP20Airdrop is Ownable {
    IERC20 public token;

    struct PaymentInfo {
        address payable payee;
        uint256 amount;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    function batchPayout(PaymentInfo[] calldata info) external onlyOwner {
        PaymentInfo[] memory infoData = info;
        for (uint256 i = 0; i < infoData.length; i++) {
            token.transfer(infoData[i].payee, infoData[i].amount);
        }
    }

    function transfer(address to, uint256 amount) external onlyOwner {
        token.transfer(to, amount);
    }
}