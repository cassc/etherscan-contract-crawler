// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ZoraModuleManager} from "../../contracts/ZoraModuleManager.sol";

contract FloorPrice {

    mapping(address => mapping(address => uint256)) public floorPrices;
    ZoraModuleManager public zmm;

    constructor(ZoraModuleManager _zmm) {
        zmm = _zmm;
    }

    function setFloorPrice(address tokenContract, address currency, uint256 floorPrice) external {
        require(msg.sender == zmm.registrar(), "NOT_REGISTRAR");

        floorPrices[tokenContract][currency] = floorPrice;
    }

    function priceAboveFloor(address tokenContract, address currency, uint256 price) external view returns(bool) {
        return price >= floorPrices[tokenContract][currency];
    }

}