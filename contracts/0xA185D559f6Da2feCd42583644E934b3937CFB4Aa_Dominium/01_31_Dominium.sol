//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Diamond} from "./external/diamond/Diamond.sol";
import {LibDiamondInitializer} from "./libraries/LibDiamondInitializer.sol";
import {IDiamondCut} from "./external/diamond/interfaces/IDiamondCut.sol";

/// @title Dominium - Shared ownership
/// @author Amit Molek
/// @dev Provides shared ownership functionality/logic. Powered by EIP-2535.
/// Note: This contract is designed to work with DominiumProxy.
/// Where this contract holds all the functionality/logic and the proxy holds all the storage
/// (so it is unique per group)
contract Dominium is Diamond {
    constructor(
        address admin,
        address anticFeeCollector,
        uint16 anticJoinFeePercentage,
        uint16 anticSellFeePercentage,
        IDiamondCut diamondCut,
        LibDiamondInitializer.DiamondInitData memory initData
    )
        payable
        Diamond(
            admin,
            anticFeeCollector,
            anticJoinFeePercentage,
            anticSellFeePercentage,
            address(diamondCut)
        )
    {
        LibDiamondInitializer._diamondInit(initData);
    }
}