// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;


import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/IAkkaPair.sol';

import './libraries/AkkaLibrary.sol';
import './libraries/SafeMath.sol';

contract AkkaGatherer {
    using SafeMath for uint;

    constructor() public {
    }

    struct Reserves {
        uint256 reserves0;
        uint256 reserves1;
    }

    function getReserves(address[] calldata pairs) external view returns (Reserves[] memory result) {

        result = new Reserves[](pairs.length);

        for (uint i = 0; i < pairs.length; i++) {
            (uint256 r0, uint256 r1) = AkkaLibrary.getReservesOrg(pairs[i]);
            result[i] = Reserves(r0, r1);
        }

    }


}