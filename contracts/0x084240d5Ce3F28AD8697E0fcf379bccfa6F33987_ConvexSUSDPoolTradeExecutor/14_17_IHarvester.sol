// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
import "../../../interfaces/IVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IHarvester {
    function crv() external view returns (IERC20);

    function cvx() external view returns (IERC20);

    function _3crv() external view returns (IERC20);

    function snx() external view returns (IERC20);

    function vault() external view returns (IVault);

    // Swap tokens to wantToken
    function harvest() external returns (uint256);

    function sweep(address _token) external;

    function setSlippage(uint256 _slippage) external;

    function rewardTokens() external view returns (address[] memory);
}