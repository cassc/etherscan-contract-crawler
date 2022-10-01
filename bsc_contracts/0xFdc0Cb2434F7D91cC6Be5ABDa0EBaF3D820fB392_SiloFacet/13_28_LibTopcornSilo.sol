/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../LibAppStorage.sol";

/**
 * @title Lib TopCorn Silo
 **/
library LibTopcornSilo {
    event TopcornDeposit(address indexed account, uint256 season, uint256 topcorns);

    function addTopcornDeposit(
        address account,
        uint32 _s,
        uint256 amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.a[account].topcorn.deposits[_s] += amount;
        emit TopcornDeposit(account, _s, amount);
    }

    function removeTopcornDeposit(
        address account,
        uint32 id,
        uint256 amount
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(id <= s.season.current, "Silo: Future crate.");
        uint256 crateAmount = s.a[account].topcorn.deposits[id];
        require(crateAmount >= amount, "Silo: Crate balance too low.");
        require(crateAmount > 0, "Silo: Crate empty.");
        s.a[account].topcorn.deposits[id] -= amount;
        return amount;
    }

    function incrementDepositedTopcorns(uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.topcorn.deposited = s.topcorn.deposited + amount;
    }

    function decrementDepositedTopcorns(uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.topcorn.deposited = s.topcorn.deposited - amount;
    }
}