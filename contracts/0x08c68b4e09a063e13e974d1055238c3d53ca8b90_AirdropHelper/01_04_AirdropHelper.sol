// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {IERC20} from "./_external/IERC20.sol";
import "./_external/Ownable.sol";

interface IWFIRE {
    function MAX_WFIRE_SUPPLY() external view returns (uint256);
}

/**
 * @title AirdropHelper contract
 *
 * @notice Owner can call transferBatch to transfer tokens to users. And store amount on mapping
 */
contract AirdropHelper is Ownable {
    IERC20 public WFIRE; // Address of WFIRE token
    IERC20 public FIRE;

    mapping(address => uint256) public userAirdrop; // WFIRE amount

    constructor() {
        initialize(msg.sender);
    }

    function setTokens(IERC20 _FIRE, IERC20 _WFIRE) external onlyOwner {
        FIRE = _FIRE;
        WFIRE = _WFIRE;
    }

    function fireToWfire(uint256 fires) public view returns (uint256) {
        return (fires * IWFIRE(address(WFIRE)).MAX_WFIRE_SUPPLY()) / FIRE.totalSupply();
    }

    function transferBatch(
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(address(WFIRE) != address(0) && address(FIRE) != address(0), "Tokens not set yet");
        require(users.length > 0 && users.length == amounts.length, "Invalid");

        uint256 totalAmount;
        for (uint256 index = 0; index < amounts.length; index += 1) {
            totalAmount += amounts[index];
        }

        FIRE.transferFrom(msg.sender, address(this), totalAmount);

        for (uint256 index = 0; index < users.length; index += 1) {
            address addr = users[index];
            uint256 amount = amounts[index];

            userAirdrop[addr] += fireToWfire(amount);

            FIRE.transfer(addr, amount);
        }
    }
}