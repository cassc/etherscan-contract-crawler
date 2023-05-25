// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./DirectBonus.sol";


abstract contract Founder is AccountStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private FOUNDER_INVESTMENT_CAP_BONUS = 20 ether;
    bytes32 constant public FOUNDER_MANAGER_ROLE = keccak256("FOUNDER_MANAGER_ROLE");

    EnumerableSet.AddressSet private _founderAccounts;

    event FounderInvestmentCapBonusUpdate(uint256 newInvestmentCapBonus);


    function isFounder(address account) public view returns(bool) {
        return _founderAccounts.contains(account);
    }


    function getFoundersCount() public view returns(uint256) {
        return _founderAccounts.length();
    }


    function setFounderInvestmentCapBonus(uint256 investmentCapBonus) public {
        require(hasRole(FOUNDER_MANAGER_ROLE, msg.sender), "Founder: must have founder manager role set investment cap bonus for founders");
        FOUNDER_INVESTMENT_CAP_BONUS = investmentCapBonus;

        emit FounderInvestmentCapBonusUpdate(investmentCapBonus);
    }


    function getFounderInvestmentCapBonus() public view returns(uint256){
        return FOUNDER_INVESTMENT_CAP_BONUS;
    }


    function addFounder(address account) public returns(bool) {
        require(hasRole(FOUNDER_MANAGER_ROLE, msg.sender), "Founder: must have founder manager role to add founder");
        return _founderAccounts.add(account);
    }


    function removeFounder(address account) public returns(bool) {
        require(hasRole(FOUNDER_MANAGER_ROLE, msg.sender), "Founder: must have founder manager role to remove founder");
        return _founderAccounts.remove(account);
    }


    function dropFounderOnSell(address account) internal returns(bool) {
        return _founderAccounts.remove(account);
    }


    function founderInvestmentBonusCapFor(address account) internal view returns(uint256) {
        return isFounder(account) ? getFounderInvestmentCapBonus() : 0;
    }
}