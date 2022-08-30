// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IFeeDistributor} from "../interfaces/IFeeDistributor.sol";

contract MultiFeeDistributor {
    function claimMany(
        uint256[] memory nftIds,
        IFeeDistributor[] memory distributors
    ) external {
        for (uint256 index = 0; index < nftIds.length; index++) {
            distributors[index].claim(nftIds[index]);
        }
    }
}