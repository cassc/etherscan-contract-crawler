// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

interface IAffiliateProgram {
    function hasAffiliate(address _addr) external view returns (bool result);

    function countReferrals(address _addr) external view returns (uint256 amount);

    function getAffiliate(address _addr) external view returns (address account);

    function getReferrals(address _addr) external view returns (address[] memory results);
}