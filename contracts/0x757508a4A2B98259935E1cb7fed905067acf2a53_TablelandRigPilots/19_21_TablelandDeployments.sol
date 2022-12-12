// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ITablelandTables.sol";

/**
 * @dev Helper library for getting an instance of ITablelandTables for the currently executing EVM chain.
 */
library TablelandDeployments {
    /**
     * Current chain does not have a TablelandTables deployment.
     */
    error ChainNotSupported(uint256 chainid);

    // TablelandTables address on Ethereum.
    address internal constant MAINNET =
        0x012969f7e3439a9B04025b5a049EB9BAD82A8C12;
    // TablelandTables address on Optimism.
    address internal constant OPTIMISTIC_ETHEREUM =
        0xfad44BF5B843dE943a09D4f3E84949A11d3aa3e6;
    // TablelandTables address on Polygon.
    address internal constant POLYGON =
        0x5c4e6A9e5C1e1BF445A062006faF19EA6c49aFeA;

    // TablelandTables address on Ethereum Goerli.
    address internal constant GOERLI =
        0xDA8EA22d092307874f30A1F277D1388dca0BA97a;
    // TablelandTables address on Optimism Goerli.
    address internal constant OPTIMISTIC_GOERLI =
        0xC72E8a7Be04f2469f8C2dB3F1BdF69A7D516aBbA;
    // TablelandTables address on Arbitrum Goerli.
    address internal constant ARBITRUM_GOERLI =
        0x033f69e8d119205089Ab15D340F5b797732f646b;
    // TablelandTables address on Polygon Mumbai.
    address internal constant POLYGON_MUMBAI =
        0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68;

    // TablelandTables address on for use with https://github.com/tablelandnetwork/local-tableland.
    address internal constant LOCAL_TABLELAND =
        0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    /**
     * @dev Returns an interface to Tableland for the currently executing EVM chain.
     *
     * The selection order is meant to reduce gas on more expensive chains.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function get() internal view returns (ITablelandTables) {
        if (block.chainid == 1) {
            return ITablelandTables(MAINNET);
        } else if (block.chainid == 10) {
            return ITablelandTables(OPTIMISTIC_ETHEREUM);
        } else if (block.chainid == 137) {
            return ITablelandTables(POLYGON);
        } else if (block.chainid == 5) {
            return ITablelandTables(GOERLI);
        } else if (block.chainid == 420) {
            return ITablelandTables(OPTIMISTIC_GOERLI);
        } else if (block.chainid == 421613) {
            return ITablelandTables(ARBITRUM_GOERLI);
        } else if (block.chainid == 80001) {
            return ITablelandTables(POLYGON_MUMBAI);
        } else if (block.chainid == 31337) {
            return ITablelandTables(LOCAL_TABLELAND);
        } else {
            revert ChainNotSupported(block.chainid);
        }
    }
}