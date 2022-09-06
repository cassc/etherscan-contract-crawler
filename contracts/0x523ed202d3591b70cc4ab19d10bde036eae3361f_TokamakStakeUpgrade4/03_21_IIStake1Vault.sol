//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IIStake1Vault {
    function closeSale() external;

    function totalRewardAmount(address _account)
        external
        view
        returns (uint256);

    function claim(address _to, uint256 _amount) external returns (bool);

    function orderedEndBlocksAll() external view returns (uint256[] memory);

    function blockTotalReward() external view returns (uint256);

    function stakeEndBlockTotal(uint256 endblock)
        external
        view
        returns (uint256 totalStakedAmount);

    function saleClosed() external view returns (bool);
}