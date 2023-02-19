//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstantVariables {
    IFla internal constant fla =
        IFla(0x619Ad2D02dBeE6ebA3CDbDA3F98430410e892882);
    address internal constant oneInchAddr =
        0x1111111254fb6c44bAC0beD2854e76F90643097d;
    IERC20 internal constant wethContract =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant stethContract =
        IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    address internal constant ethVaultAddr =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;
    IAavePriceOracle internal constant aaveOracle =
        IAavePriceOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);
}

contract Variables is ConstantVariables {
    uint256 internal status;

    address public auth;

    mapping(address => bool) public isVault;

    uint256 public premium; // premium for token vaults (in BPS)

    uint256 public premiumEth; // premium for eth vault (in BPS)
}