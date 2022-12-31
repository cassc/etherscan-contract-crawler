//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PocketUniverseTester is Ownable {
    address payable withdrawalWallet;

    uint256 public constant DEFAULT_AMOUNT = 0.0001 ether;

    constructor() {
        withdrawalWallet = payable(msg.sender);
    }

    function withdraw() external onlyOwner {
        withdrawalWallet.transfer(address(this).balance);
    }

    function randomlyWithdraw() external onlyOwner {
        uint256 multiplier = getRandomNumber();

        withdrawalWallet.transfer(DEFAULT_AMOUNT * multiplier );
    }

    function getRandomNumber() internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (randomNumber % 20) + 1;
    }

    receive() external payable {}
}