// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract sveSTG is Ownable, ERC20 {
    uint private constant MONTH = 30 days;
    uint private constant TOTAL_VESTING_MONTHS = 24;
    uint private constant TOTAL_LOCKING_MONTHS = 36;
    uint public constant TOTAL_LOCKING_SECONDS = MONTH * TOTAL_LOCKING_MONTHS;
    uint public constant VEST_START_TIME = 1679011200; // 2023-03-17 00:00:00 UTC
    uint public constant VEST_END_TIME = VEST_START_TIME + MONTH * TOTAL_VESTING_MONTHS;

    constructor() ERC20("sveSTG", "sveSTG") {}

    // ============================ Override =======================================

    // this is non-transferable
    function _beforeTokenTransfer(address from, address, uint) internal pure override {
        require(from == address(0), "non-transferable");
    }

    function balanceOf(address account) public view override returns (uint256) {
        return underlyingToSVE(super.balanceOf(account));
    }

    function totalSupply() public view override returns (uint256) {
        return underlyingToSVE(super.totalSupply());
    }

    function underlyingToSVE(uint256 _amount) public view returns (uint256) {
        uint amount = _amount * remainingMonths() / TOTAL_VESTING_MONTHS;
        return amount * remainingSeconds() / TOTAL_LOCKING_SECONDS;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function tokenBalance(address account) external view returns (uint256) {
        return super.balanceOf(account);
    }

    function remainingSeconds() public view returns (uint256) {
        if(block.timestamp >= VEST_END_TIME) {
            return 0;
        }
        uint256 timestamp = block.timestamp > VEST_START_TIME ? block.timestamp : VEST_START_TIME;
        return VEST_END_TIME - timestamp;
    }

    function remainingMonths() public view returns (uint256) {
        if(block.timestamp >= VEST_END_TIME) {
            return 0;
        }

        uint months = remainingSeconds() / MONTH;
        return months + 1 < 24 ? months + 1 : 24;
    }
}