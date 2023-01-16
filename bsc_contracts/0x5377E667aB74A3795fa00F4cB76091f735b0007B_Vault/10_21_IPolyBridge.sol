pragma solidity 0.8.17;

interface IPolyBridge {
    function lock(
        address fromAsset,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount,
        uint256 fee,
        uint256 id
    ) external payable;
}