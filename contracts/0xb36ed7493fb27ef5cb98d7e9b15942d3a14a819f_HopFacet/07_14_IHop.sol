pragma solidity 0.8.17;

struct HopMapping {
    address tokenAddress;
    address bridgeAddress;
    address relayerAddress;
}

struct HopData {
    uint256 bonderFee;
    uint256 slippage;
    uint256 deadline;
    uint256 dstAmountOutMin;
    uint256 dstDeadline;
}

interface IHop {
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;

    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadlines,
        address relayer,
        uint256 relayerFee
    ) external payable;
}