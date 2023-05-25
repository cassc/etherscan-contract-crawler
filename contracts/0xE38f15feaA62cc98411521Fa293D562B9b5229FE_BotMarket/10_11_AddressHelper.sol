// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

library AddressHelper {
    ////////////////////////////////////////////////////////////////
    /// --- COMMON CONSTANTS
    ///////////////////////////////////////////////////////////////

    /// @notice WETH address.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice ETH address.
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice AugustusSwapper contract address.
    address public constant AUGUSTUS = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /// @notice Paraswap Token pull contract address.
    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    /// @notice Address of Balancer contract.
    address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice CRV token address.
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    /// @notice BAL token address.
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;

    /// @notice Pool BAL/ETH token address.
    address public constant B_80BAL_20WETH = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;

    /// @notice Pool ID BAL/ETH token address.
    bytes32 public constant B_80BAL_20WETH_POOL_ID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;

    /// @notice Pool ID SD_BALH token address.
    bytes32 public constant SD_BAL_80BAL_20WETH_POOL_ID =
        0x2d011adf89f0576c9b722c28269fcb5d50c2d17900020000000000000000024d;

    ////////////////////////////////////////////////////////////////
    /// --- MARKET CONSTANTS
    ///////////////////////////////////////////////////////////////

    address public constant SD_FXS = 0x402F878BDd1f5C66FdAF0fabaBcF74741B68ac36;

    address public constant SD_CRV = 0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5;

    address public constant SD_CRV_POOL = 0xf7b55C3732aD8b2c2dA7c24f30A69f55c54FB717;

    address public constant SD_BAL = 0xF24d8651578a55b0C119B9910759a351A3458895;

    address public constant SD_ANGLE = 0x31429d1856aD1377A8A0079410B297e1a9e214c2;
}