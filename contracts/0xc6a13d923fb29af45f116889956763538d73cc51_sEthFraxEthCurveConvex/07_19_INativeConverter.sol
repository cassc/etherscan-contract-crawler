//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INativeConverter {
    function handle(
        bool buyToken,
        uint256 amount,
        uint256 slippage
    ) external payable returns (uint256);

    function valuate(
        bool buyToken,
        uint256 amount
    ) external view returns (uint256);
}