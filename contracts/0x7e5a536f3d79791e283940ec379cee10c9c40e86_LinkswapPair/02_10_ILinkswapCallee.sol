pragma solidity 0.6.6;

interface ILinkswapCallee {
    function linkswapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}