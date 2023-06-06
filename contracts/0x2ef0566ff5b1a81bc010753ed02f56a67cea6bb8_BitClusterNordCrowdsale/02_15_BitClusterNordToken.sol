// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC20PresetOwnablePausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BitClusterNordToken is ERC20PresetOwnablePausable("BitCluster Nord", "BCND"), ReentrancyGuard {

    using SafeERC20 for IERC20;

    mapping(address => string) private btcPayoutAddresses;
    event SetBtcPayoutAddress(address account, string btcPayoutAddress);

    /**
     * Set BTC address that mining rewards will be paid out to
     * for token holder.
     */
    function setBtcPayoutAddress(string calldata btcPayoutAddress) external {
        btcPayoutAddresses[msg.sender] = btcPayoutAddress;
        emit SetBtcPayoutAddress(msg.sender, btcPayoutAddress);
    }

    /**
     * Get BTC payout address for a given account.
     */
    function getBtcPayoutAddressOf(address account) external view returns (string memory) {
        return btcPayoutAddresses[account];
    }

    /**
     * This function is needed to allow withdrawal of ERC20 (most probably USDT)
     * funds that may be accidentally sent to this contract.
     */
    function withdrawAnyERC20Token(address tokenAddress, address to, uint amount) external onlyOwner nonReentrant {
        IERC20(tokenAddress).safeTransfer(to, amount);
    }

}