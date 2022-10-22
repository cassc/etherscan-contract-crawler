// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFarm {
    function fund(uint256 amount) external;

    function pending(uint256 pid, address user) external view returns (uint256);

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function setNFT(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _newBoostAmount
    ) external;

    function depositNFT(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function withdrawNFT(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    // View State Variables

    function totalRecycled() external view returns (uint256);

    function amountAllocatedToDao() external view returns (uint256);

    function amountAllocatedToTeam() external view returns (uint256);

    function nftDepositedAmount(
        address tokenAddress,
        uint256 tokenId,
        address user
    ) external view returns (uint256);

    function totalUserBoost(address user) external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);
}