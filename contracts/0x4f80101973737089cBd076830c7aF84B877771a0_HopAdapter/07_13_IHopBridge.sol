// SPDX-License-Identifier: MIT

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IHopBridge {
    // functions in Hop's L1Bridge
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;

    // functions in Hop's AMM wrapper
    function l2CanonicalTokenIsEth() external view returns (bool);

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
}