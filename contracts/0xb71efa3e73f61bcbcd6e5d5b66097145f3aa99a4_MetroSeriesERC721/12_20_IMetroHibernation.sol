//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMetroHibernation
{
    // getters
    function getHibernationEnabled() external returns (bool);
    function getTokenHibernationState(uint256 tokenId) external returns (bool);

    // mutating
    function startHibernation(uint256 tokenId) external;
    function endHibernation(uint256 tokenId) external;

    // accounting
    function claimRewards(uint256 tokenId, address _msgSender) external;
}