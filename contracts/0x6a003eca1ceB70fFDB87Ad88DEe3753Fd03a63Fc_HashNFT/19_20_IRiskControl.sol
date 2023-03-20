// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IRiskControl {

    function deliverRecords(uint256) external returns(uint256);

    function mintAllowed() external view returns (bool);

    function deliverAllowed() external view returns (bool);

    function offset() external view returns (uint256);

    function price() external view returns (uint256);

    function funds() external view returns (IERC20);

    // function liquidate(address, address) external;
}