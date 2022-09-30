// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMintGateway} from "../../Gateways/interfaces/IMintGateway.sol";
import {ILockGateway} from "../../Gateways/interfaces/ILockGateway.sol";

abstract contract IGatewayRegistry {
    function signatureVerifier() external view virtual returns (address);

    function chainId() external view virtual returns (uint256);

    function chainName() external view virtual returns (string memory);

    function getMintGatewaySymbols(uint256 from, uint256 count) external view virtual returns (string[] memory);

    function getLockGatewaySymbols(uint256 from, uint256 count) external view virtual returns (string[] memory);

    function getMintGatewayByToken(address token) external view virtual returns (IMintGateway);

    function getMintGatewayBySymbol(string calldata tokenSymbol) external view virtual returns (IMintGateway);

    function getRenAssetBySymbol(string calldata tokenSymbol) external view virtual returns (IERC20);

    function getLockGatewayByToken(address token) external view virtual returns (ILockGateway);

    function getLockGatewayBySymbol(string calldata tokenSymbol) external view virtual returns (ILockGateway);

    function getLockAssetBySymbol(string calldata tokenSymbol) external view virtual returns (IERC20);
}