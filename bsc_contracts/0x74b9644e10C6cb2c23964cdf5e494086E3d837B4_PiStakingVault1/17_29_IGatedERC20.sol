// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IPiTransferGate.sol";

interface IGatedERC20 is IERC20
{
    function transferGate() external view returns (IPiTransferGate);

    function setTransferGate(IPiTransferGate _transferGate) external;
}