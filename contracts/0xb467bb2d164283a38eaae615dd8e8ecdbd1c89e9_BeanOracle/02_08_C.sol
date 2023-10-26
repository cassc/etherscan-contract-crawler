// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library C {
    uint256 internal constant RATIO_FACTOR = 1e18;

    uint256 internal constant ETH_DECIMALS = 18;

    // Mainnet, Arbitrum
    address internal constant UNI_V3_FACTORY = address(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address internal constant UNI_V3_ROUTER = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

     // MAINNET
    address internal constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // //ARBITRUM
    // address internal constant WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    // SEPOLIA
    //address internal constant WETH = address(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9);

    bytes32 internal constant BOOKKEEPER_ROLE = keccak256("BOOKKEEPER_ROLE");
    bytes32 internal constant ADMIN_ROLE = 0x00;
    bytes constant BYTES_ZERO = new bytes(0);

}