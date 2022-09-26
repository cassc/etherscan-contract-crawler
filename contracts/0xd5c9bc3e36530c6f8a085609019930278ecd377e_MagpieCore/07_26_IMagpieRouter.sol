// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieRouter {
    struct Amm {
        address id;
        uint16 index;
        uint8 protocolIndex;
    }

    struct Hop {
        uint16 ammIndex;
        uint8[] path;
        bytes poolData;
    }

    struct Route {
        uint256 amountIn;
        Hop[] hops;
    }

    struct SwapArgs {
        Route[] routes;
        address[] assets;
        address payable to;
        uint256 amountOutMin;
        uint256 deadline;
    }

    function updateAmms(Amm[] calldata amms) external;

    function swap(SwapArgs memory swapArgs)
        external
        returns (uint256[] memory amountOuts);

    function updateMagpieCore(address _magpieCoreAddress) external;

    function withdraw(address weth, uint256 amount) external;

    event AmmsUpdated(Amm[] amms, address caller);
}