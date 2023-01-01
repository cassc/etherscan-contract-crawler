// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop is Ownable {
    IERC20 public immutable tokenAddr;

    constructor(IERC20 _tokenAddr) {
        tokenAddr = _tokenAddr;
    }

    function airdrop(address[] memory users, uint128[] memory amounts) external onlyOwner {
        for(uint16 i = 0 ; i < users.length ; i ++) {
            tokenAddr.transfer(users[i], amounts[i]);
        }
    }
}