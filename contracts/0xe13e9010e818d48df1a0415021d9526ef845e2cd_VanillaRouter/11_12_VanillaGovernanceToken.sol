// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 @title Governance Token for Vanilla Finance.
 */
contract VanillaGovernanceToken is ERC20("Vanilla", "VNL") {
    string private constant _ERROR_ACCESS_DENIED = "c1";
    address private immutable _owner;

    /**
        @notice Deploys the token and sets the caller as an owner.
     */
    constructor() public {
        _owner = msg.sender;
        // set the decimals explicitly to 12, for (theoretical maximum of) VNL reward of a 1ETH of profit
        // should be displayed as 1000000VNL (18-6 = 12 decimals).
        _setupDecimals(12);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, _ERROR_ACCESS_DENIED);
        _;
    }

    /**
        @notice Mints the tokens. Used only by the VanillaRouter-contract.

        @param to The recipient address of the minted tokens
        @param tradeReward The amount of tokens to be minted
     */
    function mint(address to, uint256 tradeReward) external onlyOwner {
        _mint(to, tradeReward);
    }
}