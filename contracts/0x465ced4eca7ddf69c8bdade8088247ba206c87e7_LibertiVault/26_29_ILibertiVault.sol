//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface ILibertiVault is IERC20 {
    function asset() external view returns (address);

    function other() external view returns (address);

    function deposit(
        uint256 assets,
        address receiver,
        bytes calldata data
    ) external returns (uint256);

    function depositEth(address receiver, bytes calldata data) external payable returns (uint256);

    function redeemEth(
        uint256 shares,
        address receiver,
        address _owner,
        bytes calldata data
    ) external returns (uint256);
}