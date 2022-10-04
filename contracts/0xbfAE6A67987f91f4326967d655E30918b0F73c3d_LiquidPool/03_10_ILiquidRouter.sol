// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface ILiquidRouter {

    /**
     * @dev Router interface to get merkleRoot for specific collection
    */
    function merkleRoot(
        address _nftAddress
    )
        external
        view
        returns (bytes32);

    /**
     * @dev Router interface to get chainlink ETH address for pool creation
    */
    function chainLinkETH()
        external
        view
        returns (address);

    /**
     * @dev Router interface to get chainlink Heartbeat for a specific feed
    */
    function chainLinkHeartBeat(
        address _feedAddress
    )
        external
        view
        returns (uint256);
}
