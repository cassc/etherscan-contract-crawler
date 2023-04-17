//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract JayFeeSplitter is Ownable, ReentrancyGuard {
    address payable private TEAM_WALLET;
    address payable private LP_WALLET;
    address payable private NFT_WALLET;

    uint256 public constant MIN = 1 * 10 ** 15;

    constructor() {}

    /*
     * Name: splitFees
     * Purpose: Tranfer ETH to staking contracts and team
     * Parameters: n/a
     * Return: n/a
     */
    function splitFees() external nonReentrant {
        uint256 eth = address(this).balance / (3);
        if (eth > MIN) {
            sendEth(TEAM_WALLET, eth);
            sendEth(LP_WALLET, eth);
            sendEth(NFT_WALLET, eth);
        }
    }

    function setTEAMWallet(address _address) external onlyOwner {
        require(_address != address(0x0));
        TEAM_WALLET = payable(_address);
    }

    function setNFTWallet(address _address) external onlyOwner {
        require(_address != address(0x0));
        NFT_WALLET = payable(_address);
    }

    function setLPWallet(address _address) external onlyOwner {
        require(_address != address(0x0));
        LP_WALLET = payable(_address);
    }

    /*
     * Name: sendEth
     * Purpose: Tranfer ETH tokens
     * Parameters:
     *    - @param 1: Address
     *    - @param 2: Value
     * Return: n/a
     */
    function sendEth(address _address, uint256 _value) internal {
        (bool success, ) = _address.call{value: _value}("");
        require(success, "ETH Transfer failed.");
    }

    receive() external payable {}
}