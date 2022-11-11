// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./ITransferGate.sol";

interface IGatedERC20 is IERC20
{
    function transferGate() external view returns (ITransferGate);

    function setTransferGate(ITransferGate _transferGate) external;
    function burn( uint256 amount) external;
}