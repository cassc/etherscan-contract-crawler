// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
library ParityData {
    uint256 public constant COEFF_SCALE_DECIMALS = 1e18;
    uint256 public constant FACTOR_PRICE_DECIMALS = 1e18;

    struct Amount {
        uint256 alpha;
        uint256 beta;
        uint256 gamma;
    }

    struct Position {
        uint256 tokenId;
        uint256 amount;
        uint256 userOption;
        uint256 userRisk;
        uint256 userReturn;
        Amount userWeights;
    }

    struct Fee {
        uint256 value;
        uint256 time;
    }

    struct Event {
        Amount amount;
        uint256 index;
    }

    
}