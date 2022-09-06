// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IHyphenLiquidityPool {
    function checkHashStatus(
        address tokenAddress,
        uint256 amount,
        address receiver,
        bytes memory depositHash
    ) external view returns (bytes32 hashSendTransaction, bool status);

    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string memory tag
    ) external;

    function depositNative(
        address receiver,
        uint256 toChainId,
        string memory tag
    ) external payable;

    function getRewardAmount(uint256 amount, address tokenAddress)
        external
        view
        returns (uint256 rewardAmount);

    function getTransferFee(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256 fee);

    function incentivePool(address) external view returns (uint256);
}