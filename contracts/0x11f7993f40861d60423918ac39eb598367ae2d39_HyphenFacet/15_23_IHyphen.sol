pragma solidity 0.8.17;

interface IHyphen {
    function depositNative(address receiver, uint256 toChainId, string calldata tag) external payable;

    function depositErc20(uint256 toChainId, address tokenAddress, address receiver, uint256 amount, string calldata tag) external;
}