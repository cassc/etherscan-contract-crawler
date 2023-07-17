// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICvgControlTower.sol";
import "./IBondStruct.sol";
import "./ICvgOracle.sol";

interface IBondDepository {
    // Deposit Principle token in Treasury through Bond contract
    function deposit(uint256 tokenId, uint256 amount, address receiver) external;

    function depositToLock(uint256 amount, address receiver) external returns (uint256 cvgToMint);

    function getBondView() external view returns (IBondStruct.BondView memory);

    function bondInfos(uint256 tokenId) external view returns (IBondStruct.BondPending memory);

    function getTokenVestingInfo(uint256 tokenId) external view returns (IBondStruct.TokenVestingInfo memory);

    function redeem(uint256 tokenId, address recipient, address operator) external returns (uint256);

    function bondParams() external view returns (IBondStruct.BondParams memory);

    function initialize(
        ICvgControlTower _cvgControlTower,
        IBondStruct.BondParams calldata _bondParams,
        IOracleStruct.OracleParams calldata _oracleParams
    ) external;
}