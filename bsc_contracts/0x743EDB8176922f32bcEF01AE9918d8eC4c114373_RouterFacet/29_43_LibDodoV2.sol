// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {IDodoV2Pool} from "../interfaces/dodo-v2/IDodoV2Pool.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibRouter, Hop} from "./LibRouter.sol";

library LibDodoV2 {
    using LibAsset for address;

    function getDodoV2Data(bytes32[] memory poolData)
        private
        pure
        returns (address[] memory poolAddresses, uint256[] memory directions)
    {
        uint256 l = poolData.length;
        poolAddresses = new address[](l);
        directions = new uint256[](l);

        assembly {
            let i := 0
            let poolAddressesPosition := add(poolAddresses, 32)
            let directionsPosition := add(directions, 32)

            for {

            } lt(i, l) {
                i := add(i, 1)
                poolAddressesPosition := add(poolAddressesPosition, 32)
                directionsPosition := add(directionsPosition, 32)
            } {
                let poolDataPosition := add(add(poolData, 32), mul(i, 32))

                mstore(poolAddressesPosition, shr(96, mload(poolDataPosition)))
                mstore(directionsPosition, shr(248, shl(160, mload(poolDataPosition))))
            }
        }
    }

    function swapDodoV2(Hop memory h) internal {
        uint256 i;
        uint256 l = h.poolData.length;
        (address[] memory poolAddresses, uint256[] memory directions) = getDodoV2Data(h.poolData);
        h.path[0].transfer(payable(poolAddresses[0]), h.amountIn);

        for (i = 0; i < l; ) {
            if (directions[i] == 1) {
                IDodoV2Pool(poolAddresses[i]).sellBase((i == l - 1) ? address(this) : poolAddresses[i + 1]);
            } else {
                IDodoV2Pool(poolAddresses[i]).sellQuote((i == l - 1) ? address(this) : poolAddresses[i + 1]);
            }

            unchecked {
                i++;
            }
        }
    }
}