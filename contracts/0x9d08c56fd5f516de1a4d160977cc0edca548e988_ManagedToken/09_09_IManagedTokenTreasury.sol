// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "openzeppelin/access/IAccessControl.sol";

interface IManagedTokenTreasury is IAccessControl {
    function AI_EXECUTOR_ROLE() external returns (bytes32);
    function PROTOCOL_OWNER_ROLE() external returns (bytes32);

    function onTaxSent(uint256 amount, address sender) external;

    function setMinTokensToSwap(uint256 minTokensToSwap) external;
    function setProtocolRevenueAddress(address protocolAddress) external;
    function setProtocolRevenueBips(uint16 bips) external;
    function sell(uint256 tokenAmount, uint256 minAmountOut) external;
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external;
    function buyBackAndBurn(uint256 amountEth) external;
    function buyBack(uint256 amountEth) external returns (uint256 amountToken);
    function burn(uint256 amount) external;
}