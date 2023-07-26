pragma solidity ^0.8.0;

interface IAdapter {
    event Bridge(
        address recipient,
        address aggregator,
        uint256 destChain,
        address srcToken,
        address destToken,
        uint256 srcAmount
    );

    event Fee(address srcToken, address feeWallet, uint256 fee);

    function bridge(
        address recipient,
        address aggregator,
        address spender,
        uint256 destChain,
        address srcToken,
        address destToken,
        uint256 srcAmount,
        bytes calldata data,
        uint256 fee,
        address payable feeWallet
    ) external payable;
}